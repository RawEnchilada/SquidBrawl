using Godot;
using System;
using System.Collections.Generic;
using System.Text.Json;

namespace Terrain;

public partial class Map : Node3D
{

    const string mapsFolder = "./maps/";

    [Export]
    public Vector3 chunks = new(8, 6, 8);
    [Export]
    public int chunkSize = 12;

    private List<Dictionary<string, object>> chunkData = new();
    private List<MaterialArea> materialAreas = new();
    private bool modified = false;
    private Node3D terrain;
    private StaticBody3D staticBody;

    private static readonly Material DefaultMaterial = new StandardMaterial3D();

    public override void _Ready()
    {
        terrain = GetNode<Node3D>("Terrain");
        staticBody = GetNode<StaticBody3D>("StaticBody3D");
    }

    public void LoadMap(string mapname)
    {
        if (System.IO.File.Exists(mapname+".map"))
        {
            byte[] data = System.IO.File.ReadAllBytes(mapsFolder+mapname);
            Dictionary<string, object> root_dict = (Dictionary<string, object>)JsonSerializer.Deserialize(data, typeof(List<Dictionary<string, object>>));
            float[,,] valueField = (float[,,])root_dict["valueField"];
            foreach (Dictionary<string, object> dict in root_dict["materialAreas"] as List<Dictionary<string, object>>){
                MaterialArea area = new()
                {
                    Size = (Vector3)dict["size"],
                    GlobalPosition = (Vector3)dict["global_position"],
                    apply_material = (Material)dict["apply_material"]
                };
                materialAreas.Add(area);
            }
            CreateFromTensor(valueField, materialAreas);
        }
    }

    public static void SaveMapAs(float[,,] terrainTensor, List<MaterialArea> materialAreas,string mapname)
    {
        Dictionary<string, object> root_dict = new()
        {
            {"valueField", terrainTensor},
            {"materialAreas", materialAreas}
        };
        byte[] data = JsonSerializer.SerializeToUtf8Bytes(root_dict);
        System.IO.File.WriteAllBytes(mapsFolder+mapname+".map", data);
    }

    public void CreateFromTensor(float[,,] terrainTensor, List<MaterialArea> materialAreas)
    {
        // Calculate chunks from tensor dimensions
        chunks = new Vector3(
            terrainTensor.GetLength(0) / chunkSize,
            terrainTensor.GetLength(1) / chunkSize,
            terrainTensor.GetLength(2) / chunkSize
        );
        this.materialAreas = materialAreas;

        Vector3 center = new(chunks.X * chunkSize / 2, 0, chunks.Z * chunkSize / 2);
        terrain.GlobalPosition = -center;
        staticBody.GlobalPosition = -center;

        GenerateFromTensor(terrainTensor);
    }

    private void GenerateFromTensor(float[,,] terrainTensor)
    {
        chunkData.Clear();
        
        for (int x = 0; x < chunks.X; x++)
        {
            for (int y = 0; y < chunks.Y; y++)
            {
                for (int z = 0; z < chunks.Z; z++)
                {
                    Vector3 chunkPos = new(x, y, z);
                    Vector3 chunkCenter = chunkPos * (chunkSize - 1) + new Vector3(chunkSize / 2.0f, chunkSize / 2.0f, chunkSize / 2.0f);
                    float[,,] valueField = ExtractChunkFromTensor(terrainTensor, chunkPos);
                    ArrayMesh mesh = CreateMarchedMesh(valueField,chunkCenter);
                    var instances = AddMeshAndCollision(mesh, chunkPos * (chunkSize - 1));
                    
                    chunkData.Add(new Dictionary<string, object>
                    {
                        {"value_field", valueField},
                        {"collision", instances["collision"]},
                        {"center", chunkCenter}
                    });
                }
            }
        }
    }

    private float[,,] ExtractChunkFromTensor(float[,,] sourceTensor, Vector3 chunkPos)
    {
        float[,,] chunkData = new float[chunkSize, chunkSize, chunkSize];
        
        int xStart = (int)chunkPos.X * chunkSize;
        int yStart = (int)chunkPos.Y * chunkSize;
        int zStart = (int)chunkPos.Z * chunkSize;

        for (int x = 0; x < chunkSize; x++)
        {
            for (int y = 0; y < chunkSize; y++)
            {
                for (int z = 0; z < chunkSize; z++)
                {
                    chunkData[x, y, z] = sourceTensor[
                        xStart + x,
                        yStart + y,
                        zStart + z
                    ];
                }
            }
        }
        return chunkData;
    }


    private ArrayMesh CreateMarchedMesh(float[,,] tensor, Vector3 chunkCenter)
    {
        SurfaceTool st = MarchingCubes.ApplyMarchingCubes(tensor, chunkSize);
        st.SetMaterial(GetMaterialForChunk(chunkCenter));
        return st.Commit();
    }

    private Material GetMaterialForChunk(Vector3 chunkCenter)
    {
        foreach (var area in materialAreas)
        {
            if (chunkCenter.X >= area.GlobalPosition.X && chunkCenter.X <= area.GlobalPosition.X + area.Size.X &&
                chunkCenter.Z >= area.GlobalPosition.Z && chunkCenter.Z <= area.GlobalPosition.Z + area.Size.Z &&
                chunkCenter.Y >= area.GlobalPosition.Y && chunkCenter.Y <= area.GlobalPosition.Y + area.Size.Y)
            {
                return area.apply_material;
            }
        }
        return DefaultMaterial;
    }

    private Dictionary<string, Node3D> AddMeshAndCollision(ArrayMesh mesh, Vector3 chunkPos)
    {
        MeshInstance3D meshInstance = new()
        {
            Mesh = mesh,
            Position = chunkPos
        };

        CollisionShape3D collisionShape = new()
        {
            Shape = mesh.CreateTrimeshShape(),
            Position = chunkPos
        };
        staticBody.AddChild(collisionShape);
        terrain.AddChild(meshInstance);
        return new Dictionary<string, Node3D>
        {
            {"mesh", meshInstance},
            {"collision", collisionShape}
        };
    }

    private static void RemoveChunk(Dictionary<string, object> chunk)
    {
        ((MeshInstance3D)chunk["mesh"]).QueueFree();
        ((CollisionShape3D)chunk["collision"]).QueueFree();
    }

    public void OnBulletExploded(Vector3 explosionPosition, float explosionRadius)
    {
        modified = true;
        float halfChunkSize = chunkSize / 2.0f;
        Vector3 relativeExplosionPosition = explosionPosition - terrain.GlobalPosition;

        var closestChunks = new List<Dictionary<string, object>>();
        foreach (var chunk in chunkData)
        {
            float distance = ((Vector3)chunk["center"] - relativeExplosionPosition).Length();
            closestChunks.Add(new Dictionary<string, object>
            {
                {"chunk", chunk},
                {"distance", distance}
            });
        }

        closestChunks.Sort((a, b) => ((float)a["distance"]).CompareTo((float)b["distance"]));
        closestChunks = closestChunks.GetRange(0, Math.Min(8, closestChunks.Count));

        foreach (var entry in closestChunks)
        {
            var chunk = (Dictionary<string, object>)entry["chunk"];
            Vector3 chunkCenter = (Vector3)chunk["center"];
            Vector3 chunkPos = chunkCenter - new Vector3(halfChunkSize, halfChunkSize, halfChunkSize);
            float[,,] valueField = (float[,,])chunk["value_field"];

            for (int x = 0; x < chunkSize; x++)
            {
                for (int y = 0; y < chunkSize; y++)
                {
                    for (int z = 0; z < chunkSize; z++)
                    {
                        Vector3 voxelPos = chunkPos + new Vector3(x, y, z);
                        if ((voxelPos - relativeExplosionPosition).Length() <= explosionRadius)
                        {
                            valueField[x, y, z] = -1.0f;
                        }
                    }
                }
            }

            ArrayMesh mesh = CreateMarchedMesh(valueField,chunkCenter);
            RemoveChunk(chunk);
            var instances = AddMeshAndCollision(mesh, chunkPos);
            chunk["mesh"] = instances["mesh"];
            chunk["collision"] = instances["collision"];
        }
    }
}
