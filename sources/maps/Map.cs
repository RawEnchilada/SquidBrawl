using Godot;
using System;
using System.Collections.Generic;
using System.Text.Json;

namespace Terrain;

public partial class Map : Node3D
{
    const bool DEBUG_MATERIALS = true;
    const string mapsFolder = "./maps/";

    public Vector3 chunks = new(8, 6, 8);

    public const int CHUNK_SIZE = 12;

    private List<Dictionary<string, object>> chunkData = new();
    private List<MaterialArea> materialAreas = new();
    private bool modified = false;
    private Node3D terrain;
    private StaticBody3D staticBody;
    private Node3D spawnAreas;
    private Node3D shark;

    private static readonly Material DefaultMaterial = new StandardMaterial3D();

    public override void _Ready()
    {
        terrain = GetNode<Node3D>("Terrain");
        staticBody = GetNode<StaticBody3D>("StaticBody3D");
        spawnAreas = GetNode<Node3D>("SpawnAreas");
        shark = GetNode<Node3D>("Shark");
    }

    public Vector3 GetSpawnPoint(int id)
    {
        return spawnAreas.GetChild<SpawnArea>(id % spawnAreas.GetChildCount()).GlobalPosition;
    }

    public void LoadMap(string mapname)
    {
        if (System.IO.File.Exists(mapsFolder + mapname + ".map"))
        {
            byte[] data = System.IO.File.ReadAllBytes(mapsFolder + mapname + ".map");

            var options = new JsonSerializerOptions();
            options.Converters.Add(new Float3DSerializer());
            options.Converters.Add(new Vector3DSerializer());

            var root_dict = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(data, options);

            float[,,] valueField = root_dict["valueField"].Deserialize<float[,,]>(options);

            materialAreas.Clear(); // Clear existing material areas
            var materialAreasList = root_dict["materialAreas"].Deserialize<List<Dictionary<string, JsonElement>>>(options);
            foreach (var dict in materialAreasList)
            {
                MaterialArea area = new()
                {
                    Size = dict["size"].Deserialize<Vector3>(options),
                    Position = dict["position"].Deserialize<Vector3>(options),
                    apply_material = dict["apply_material"].GetString()
                };
                materialAreas.Add(area);
            }

            foreach (Node child in spawnAreas.GetChildren())
            {
                child.QueueFree();
            }
            var spawnAreasList = root_dict["spawnAreas"].Deserialize<List<Vector3>>(options);
            foreach (Vector3 spawnArea in spawnAreasList)
            {
                SpawnArea area = new();
                spawnAreas.AddChild(area);
                area.GlobalPosition = spawnArea;
            }
            CreateFromTensor(valueField, materialAreas);
            GD.Print("Map "+mapname+".map loaded, "+chunkData.Count+" chunks have been created.");
        } else{
            GD.PrintErr("Map file "+mapname+".map not found.");
        }
    }



    private void CreateFromTensor(float[,,] terrainTensor, List<MaterialArea> materialAreas)
    {
        // Calculate chunks from tensor dimensions
        chunks = new Vector3(
            terrainTensor.GetLength(0) / CHUNK_SIZE,
            terrainTensor.GetLength(1) / CHUNK_SIZE,
            terrainTensor.GetLength(2) / CHUNK_SIZE
        );
        shark.Set("radius", Math.Max(chunks.X * CHUNK_SIZE, chunks.Z * CHUNK_SIZE) / 2.0f + 5.0f);
        this.materialAreas = materialAreas;

        Vector3 center = new(chunks.X * CHUNK_SIZE / 2, 0, chunks.Z * CHUNK_SIZE / 2);
        terrain.GlobalPosition = -center;
        staticBody.GlobalPosition = -center;
        spawnAreas.GlobalPosition = -center; 
        chunkData.Clear();
        
        for (int x = 0; x < chunks.X; x++)
        {
            for (int y = 0; y < chunks.Y; y++)
            {
                for (int z = 0; z < chunks.Z; z++)
                {
                    Vector3 chunkPos = new(x, y, z);
                    Vector3 chunkCenter = chunkPos * (CHUNK_SIZE - 1) + new Vector3(CHUNK_SIZE / 2.0f, CHUNK_SIZE / 2.0f, CHUNK_SIZE / 2.0f);
                    float[,,] valueField = ExtractChunkFromTensor(terrainTensor, chunkPos);
                    ArrayMesh mesh = CreateMarchedMesh(valueField,chunkCenter);
                    var instances = AddMeshAndCollision(mesh, chunkPos * (CHUNK_SIZE - 1));
                    
                    chunkData.Add(new Dictionary<string, object>
                    {
                        {"value_field", valueField},
                        {"collision", instances["collision"]},
                        {"center", chunkCenter}
                    });
                }
            }
        }
        GD.Print("Created "+chunkData.Count+" chunks.");
    }

    private float[,,] ExtractChunkFromTensor(float[,,] sourceTensor, Vector3 chunkPos)
    {
        var maxSize = chunks * CHUNK_SIZE;
        float[,,] chunkData = new float[CHUNK_SIZE, CHUNK_SIZE, CHUNK_SIZE];
        
        int xStart = (int)chunkPos.X * CHUNK_SIZE;
        int yStart = (int)chunkPos.Y * CHUNK_SIZE;
        int zStart = (int)chunkPos.Z * CHUNK_SIZE;

        for (int x = 0; x < CHUNK_SIZE; x++)
        {
            for (int y = 0; y < CHUNK_SIZE; y++)
            {
                for (int z = 0; z < CHUNK_SIZE; z++)
                {
                    if(xStart + x == 0 || yStart + y == 0 || zStart + z == 0 || xStart + x == maxSize.X - 1 || yStart + y == maxSize.Y - 1 || zStart + z == maxSize.Z - 1)
                    {
                        chunkData[x, y, z] = -1.0f;
                        continue;
                    }else{
                        chunkData[x, y, z] = sourceTensor[
                            xStart + x,
                            yStart + y,
                            zStart + z
                        ];
                    }
                }
            }
        }
        return chunkData;
    }


    private ArrayMesh CreateMarchedMesh(float[,,] tensor, Vector3 chunkCenter)
    {
        SurfaceTool st = MarchingCubes.ApplyMarchingCubes(tensor, CHUNK_SIZE);
        st.SetMaterial(GetMaterialForChunk(chunkCenter));
        ArrayMesh mesh = st.Commit();
        return mesh;
    }

    private Material GetMaterialForChunk(Vector3 chunkCenter)
    {
        if(DEBUG_MATERIALS){
            var maxSize = chunks * CHUNK_SIZE;
            var material = new StandardMaterial3D
            {
                AlbedoColor = new Color(chunkCenter.X/maxSize.X, chunkCenter.Y/maxSize.Y, chunkCenter.Z/maxSize.Z)
            };
            return material;
        }else{
            foreach (var area in materialAreas)
            {
                if (chunkCenter.X >= area.Position.X && chunkCenter.X <= area.Position.X + area.Size.X &&
                    chunkCenter.Z >= area.Position.Z && chunkCenter.Z <= area.Position.Z + area.Size.Z &&
                    chunkCenter.Y >= area.Position.Y && chunkCenter.Y <= area.Position.Y + area.Size.Y)
                {
                    return ResourceLoader.Load<Material>(area.apply_material);
                }
            }
            return DefaultMaterial;
        }
    }

    private Dictionary<string, Node3D> AddMeshAndCollision(ArrayMesh mesh, Vector3 chunkPos)
    {
        MeshInstance3D meshInstance = new()
        {
            Mesh = mesh,
            Position = chunkPos,
            Layers = 2
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
        float halfChunkSize = CHUNK_SIZE / 2.0f;
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

            for (int x = 0; x < CHUNK_SIZE; x++)
            {
                for (int y = 0; y < CHUNK_SIZE; y++)
                {
                    for (int z = 0; z < CHUNK_SIZE; z++)
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
