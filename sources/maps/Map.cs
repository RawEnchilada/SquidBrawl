using Godot;
using System;
using System.Collections.Generic;
using System.Text.Json;

namespace Terrain;

[Tool]
public partial class Map : Node3D
{
    static List<PackedScene> clutterScenes = new(){
        ResourceLoader.Load<PackedScene>("res://sources/maps/assets/clutter/box.tscn"),
        ResourceLoader.Load<PackedScene>("res://sources/maps/assets/clutter/barrel.tscn"),
        ResourceLoader.Load<PackedScene>("res://sources/maps/assets/clutter/planks.tscn")
    };
    const bool DEBUG_MATERIALS = true;
    const string mapsFolder = "./maps/";

    [Export]
    public FastNoiseLite noiseMap;
    [Export]
    public int seed;
    [Export]
    public bool generate = false;
    [Export]
    public Vector3 chunks = new(8, 6, 8);
    [Export]
    public int clutterCount = 25;

    public const int CHUNK_SIZE = 12; // How big a chunk is in Godot units. For example, a CHUNK_SIZE of 12 means a chunk top corner is at 12,12,12.

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

    public override void _Process(double delta)
    {
        if(generate){
            generate = false;
            terrain = GetNode<Node3D>("Terrain");
            staticBody = GetNode<StaticBody3D>("StaticBody3D");
            var valueField = GenerateFromNoise((int)chunks.X, (int)chunks.Y, (int)chunks.Z, seed);
            CreateFromTensor(valueField, new List<MaterialArea>());
        }
    }

    public Vector3 GetSpawnPoint(int id)
    {
        return spawnAreas.GetChild<SpawnArea>(id % spawnAreas.GetChildCount()).GlobalPosition;
    }

    public void LoadMap(string mapname)
    {
        byte[] data = System.IO.File.ReadAllBytes(mapsFolder + mapname + ".map");

        var options = new JsonSerializerOptions();
        options.Converters.Add(new Vector3DSerializer());

        var root_dict = JsonSerializer.Deserialize<Dictionary<string, JsonElement>>(data, options);

        seed = root_dict["seed"].Deserialize<int>(options);
        chunks = root_dict["chunks"].Deserialize<Vector3>(options);

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
        var valueField = GenerateFromNoise((int)chunks.X, (int)chunks.Y, (int)chunks.Z, seed);
        CreateFromTensor(valueField, materialAreas);
    }

    private float[,,] GenerateFromNoise(int cx,int cy,int cz,int _seed){
        noiseMap.Seed = _seed;
        float[,,] full_field = new float[cx*CHUNK_SIZE, cy*CHUNK_SIZE, cz*CHUNK_SIZE];
        for (int x = 0; x < cx*CHUNK_SIZE; x++)
        {
            for (int y = 0; y < cy*CHUNK_SIZE; y++)
            {
                for (int z = 0; z < cz*CHUNK_SIZE; z++)
                {
                    var noiseValue = noiseMap.GetNoise3D(x, y, z);
                    var modifier_x = 1.0f-MathF.Abs(x - cx*CHUNK_SIZE/2.0f)/cx*CHUNK_SIZE/2.0f;
                    var modifier_y = 1.0f-MathF.Abs(y - cy*CHUNK_SIZE/2.0f)/cy*CHUNK_SIZE/2.0f;
                    var modifier_z = 1.0f-MathF.Abs(z - cz*CHUNK_SIZE/2.0f)/cz*CHUNK_SIZE/2.0f;
                    var mod = (modifier_x+modifier_y+modifier_z) - 0.5f;
                    full_field[x,y,z] = noiseValue*mod;
                }
            }
        }
        return full_field;
    }



    private void CreateFromTensor(float[,,] terrainTensor, List<MaterialArea> materialAreas)
    {
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
                        {"mesh", instances["mesh"]},
                        {"center", chunkCenter}
                    });
                }
            }
        }
        GD.Print("Created "+chunkData.Count+" chunks.");
    }


    private float[,,] ExtractChunkFromTensor(float[,,] sourceTensor, Vector3 chunkPos)
    {
        float[,,] chunkData = new float[CHUNK_SIZE, CHUNK_SIZE, CHUNK_SIZE];

        for (int x = 0; x < CHUNK_SIZE; x++)
        {
            for (int y = 0; y < CHUNK_SIZE; y++)
            {
                for (int z = 0; z < CHUNK_SIZE; z++)
                {
                    if (chunkPos.X == 0 && x == 0 || chunkPos.X == chunks.X - 1 && x == CHUNK_SIZE - 1 ||
                        chunkPos.Y == 0 && y == 0 || chunkPos.Y == chunks.Y - 1 && y == CHUNK_SIZE - 1 ||
                        chunkPos.Z == 0 && z == 0 || chunkPos.Z == chunks.Z - 1 && z == CHUNK_SIZE - 1)
                    {
                        chunkData[x, y, z] = -1.0f;
                        continue;
                    }else{
                        chunkData[x, y, z] = sourceTensor[
                            (int)(chunkPos.X * (CHUNK_SIZE - 1) + x),
                            (int)(chunkPos.Y * (CHUNK_SIZE - 1) + y),
                            (int)(chunkPos.Z * (CHUNK_SIZE - 1) + z)
                        ];
                    }
                }
            }
        }
        return chunkData;
    }


    private ArrayMesh CreateMarchedMesh(float[,,] chunktensor, Vector3 chunkCenter)
    {
        SurfaceTool st = MarchingCubes.ApplyMarchingCubes(chunktensor, CHUNK_SIZE);
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

    private void LoadClutter(int count,Node parent = null){
        Vector3 spawnpoint = new Vector3(0.0f,(chunks.Y+1)*CHUNK_SIZE,0.0f);
        var random = new RandomNumberGenerator();
        for(int i = 0; i < count; i++){
            int index = random.RandiRange(0,clutterScenes.Count-1);
            Node3D clutter = clutterScenes[index].Instantiate() as Node3D;
            parent.AddChild(clutter,true);
            clutter.Position = spawnpoint;
            spawnpoint += new Vector3(0.0f,1.0f,0.0f);
        }
    }
}
