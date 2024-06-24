using Godot;
using System;
using System.Collections.Generic;
using System.Text.Json;

namespace Terrain;

public partial class GeneratedIsland : Node3D
{
    [Export]
    public FastNoiseLite plantNoiseMap;
    [Export]
    public FastNoiseLite noiseMap;
    [Export]
    public Vector3 chunks = new(8, 6, 8);
    [Export]
    public int chunkSize = 12;

    private List<Dictionary<string, object>> chunkData = new();
    private bool modified = false;

    private Node3D terrain;
    private StaticBody3D staticBody;

    private static readonly PackedScene PalmScene = (PackedScene)ResourceLoader.Load("res://sources/maps/assets/trees/palm.glb");
    private static readonly PackedScene Plant01Scene = (PackedScene)ResourceLoader.Load("res://sources/maps/assets/trees/plant01.glb");
    private static readonly PackedScene Plant02Scene = (PackedScene)ResourceLoader.Load("res://sources/maps/assets/trees/plant02.glb");
    private static readonly PackedScene Plant03Scene = (PackedScene)ResourceLoader.Load("res://sources/maps/assets/trees/plant03.glb");

    private static readonly Material GroundMaterial = (Material)ResourceLoader.Load("res://sources/shaders/ground.tres");

    public override void _Ready()
    {
        terrain = GetNode<Node3D>("Terrain");
        staticBody = GetNode<StaticBody3D>("StaticBody3D");
    }

    public void LoadChunkDataSerialized(byte[] data)
    {
        chunkData = (List<Dictionary<string, object>>)JsonSerializer.Deserialize(data, typeof(List<Dictionary<string, object>>));
    }

    public byte[] SaveChunkDataSerialized()
    {
        if (modified)
        {
            List<Dictionary<string, object>> data = new();
            foreach (var chunk in chunkData)
            {
                data.Add(new Dictionary<string, object>
                {
                    {"value_field", chunk["value_field"]},
                    {"center", chunk["center"]}
                });
            }

            return JsonSerializer.SerializeToUtf8Bytes(data);
        }

        return Array.Empty<byte>();
    }



    public void CreateIsland(int mapSeed)
    {
        Vector3 center = new(chunks.X * chunkSize / 2, 0, chunks.Z * chunkSize / 2);
        terrain.GlobalPosition = -center;
        staticBody.GlobalPosition = -center;
        if (chunkData.Count == 0)
        {
            Generate(mapSeed);
            modified = false;
        }
        else
        {
            foreach (var chunk in chunkData)
            {
                ArrayMesh mesh = CreateMarchedMesh((float[,,])chunk["value_field"]);
                var instances = AddMeshAndCollision(mesh, (Vector3)chunk["center"] - new Vector3(chunkSize / 2.0f, chunkSize / 2.0f, chunkSize / 2.0f));
                chunk["mesh"] = instances["mesh"];
                chunk["collision"] = instances["collision"];
            }
            modified = true;
        }
        SpawnAreas();
    }

    public void Generate(int rseed = 1)
    {
        noiseMap.Seed = rseed;
        for (int x = 0; x < chunks.X; x++)
        {
            for (int y = 0; y < chunks.Y; y++)
            {
                for (int z = 0; z < chunks.Z; z++)
                {
                    Vector3 chunkPos = new(x, y, z);
                    float[,,] valueField = GenerateValueField(chunkPos);
                    ArrayMesh mesh = CreateMarchedMesh(valueField);
                    var instances = AddMeshAndCollision(mesh, chunkPos * (chunkSize - 1));
                    chunkData.Add(new Dictionary<string, object>
                    {
                        {"value_field", valueField},
                        {"mesh", instances["mesh"]},
                        {"collision", instances["collision"]},
                        {"center", chunkPos * (chunkSize - 1) + new Vector3(chunkSize / 2.0f, chunkSize / 2.0f, chunkSize / 2.0f)}
                    });
                }
            }
        }
    }

    private float[,,] GenerateValueField(Vector3 chunkPos)
    {
        float[,,] tensor = new float[chunkSize, chunkSize, chunkSize];
        for (int x = 0; x < chunkSize; x++)
        {
            for (int y = 0; y < chunkSize; y++)
            {
                for (int z = 0; z < chunkSize; z++)
                {
                    if (chunkPos.X == 0 && x == 0 || chunkPos.X == chunks.X - 1 && x == chunkSize - 1 ||
                        chunkPos.Y == 0 && y == 0 || chunkPos.Y == chunks.Y - 1 && y == chunkSize - 1 ||
                        chunkPos.Z == 0 && z == 0 || chunkPos.Z == chunks.Z - 1 && z == chunkSize - 1)
                    {
                        tensor[x, y, z] = -1.0f;
                    }
                    else
                    {
                        tensor[x, y, z] = noiseMap.GetNoise3D(chunkPos.X * (chunkSize - 1) + x, chunkPos.Y * (chunkSize - 1) + y, chunkPos.Z * (chunkSize - 1) + z);
                    }
                }
            }
        }
        return tensor;
    }

    private ArrayMesh CreateMarchedMesh(float[,,] tensor)
    {
        SurfaceTool st = MarchingCubes.ApplyMarchingCubes(tensor, chunkSize);
        st.SetMaterial(GroundMaterial);
        return st.Commit();
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

            ArrayMesh mesh = CreateMarchedMesh(valueField);
            RemoveChunk(chunk);
            var instances = AddMeshAndCollision(mesh, chunkPos);
            chunk["mesh"] = instances["mesh"];
            chunk["collision"] = instances["collision"];
        }
    }

    private static readonly PackedScene AreaScene = (PackedScene)ResourceLoader.Load("res://sources/maps/areas/spawn_area.tscn");

    private void SpawnAreas()
    {
        List<Vector3> validPoints = new();
        Vector3 center = new(chunks.X * chunkSize / 2, 0, chunks.Z * chunkSize / 2);

        for (int x = 1; x < chunks.X - 1; x++)
        {
            for (int z = 1; z < chunks.Z - 1; z++)
            {
                Vector3 chunkPos = new(x, 0, z);
                float value = noiseMap.GetNoise3D(x * (chunkSize - 1) + chunkSize / 2.0f, chunks.Y * (chunkSize - 1), z * (chunkSize - 1) + chunkSize / 2.0f);

                if (value > 0.0f)
                {
                    validPoints.Add(GlobalPosition +chunkPos * chunkSize + new Vector3(chunkSize / 2.0f, chunks.Y * chunkSize, chunkSize / 2.0f) - center);
                }
            }
        }

        SpawnAreasOnSurfaces(validPoints.ToArray());
    }

    private void SpawnAreasOnSurfaces(Vector3[] surfaces)
    {
        if (surfaces.Length == 0)
        {
            Array.Resize(ref surfaces, 1);
            surfaces[0] = Vector3.Up * chunks.Y * chunkSize;
        }

        foreach (Vector3 surface in surfaces)
        {
            Node3D instance = (Node3D)AreaScene.Instantiate();
            AddChild(instance);
            instance.GlobalPosition = surface+Vector3.Up*0.1f;
        }
    }
}
