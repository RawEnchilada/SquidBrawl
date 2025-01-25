using Godot;
using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Linq;


namespace Terrain;


[Tool]
public partial class Editor : Node3D
{
    const string mapsFolder = "./maps/";

    [Export]
    string mapName = "default";
    [Export]
    bool save = false;

    CsgCombiner3D csgCombiner;
    Node3D materialAreas;
    Node3D spawnAreas;
    
	public override void _Ready()
	{
        csgCombiner = GetNode<CsgCombiner3D>("CSGCombiner");
        materialAreas = GetNode<Node3D>("MaterialAreas");
        spawnAreas = GetNode<Node3D>("SpawnAreas");
    }
    public override void _Process(double delta)
    {
        if (save)
        {
            csgCombiner = GetNode<CsgCombiner3D>("CSGCombiner");
            materialAreas = GetNode<Node3D>("MaterialAreas");
            spawnAreas = GetNode<Node3D>("SpawnAreas");
            save = false;
            SaveMapAs(GetValueField(), GetMaterialAreas(), GetSpawnAreas(), mapName);
        }
    }

    public static void SaveMapAs(float[,,] terrainTensor, List<MaterialArea> materialAreas, List<SpawnArea> spawnAreas, string mapname)
    {
        List<Dictionary<string, object>> materialAreasSerialized = new();
        List<Vector3> spawnAreasSerialized = new();
        foreach (MaterialArea area in materialAreas)
        {
            materialAreasSerialized.Add(new Dictionary<string, object>
            {
                {"size", area.Size},
                {"position", area.Position},
                {"apply_material", area.apply_material}
            });
        }
        foreach (SpawnArea area in spawnAreas)
        {
            spawnAreasSerialized.Add(area.GlobalPosition);
        }

        Dictionary<string, object> root_dict = new()
        {
            {"valueField", terrainTensor},
            {"materialAreas", materialAreasSerialized},
            {"spawnAreas", spawnAreasSerialized}
        };
        GD.Print("Serialized "+materialAreas.Count+" material areas and "+spawnAreas.Count+" spawn areas to "+mapname+".map");
        var solid_count = 0;
        for (int x = 0; x < terrainTensor.GetLength(0); x++)
        {
            for (int y = 0; y < terrainTensor.GetLength(1); y++)
            {
                for (int z = 0; z < terrainTensor.GetLength(2); z++)
                {
                    if (terrainTensor[x, y, z] == 1.0f)
                    {
                        solid_count++;
                    }
                }
            }
        }
        if (solid_count == 0)
        {
            GD.Print("Field is empty, aborted saving.");
            return;
        }else{
            GD.Print("Field is looking good, it has "+solid_count+" solid points.");
        }
        var options = new JsonSerializerOptions();
        options.Converters.Add(new Float3DSerializer());
        options.Converters.Add(new Vector3DSerializer());

        byte[] data = JsonSerializer.SerializeToUtf8Bytes(root_dict, options);
        System.IO.File.WriteAllBytes(mapsFolder+mapname+".map", data);
    }


    private List<MaterialArea> GetMaterialAreas()
    {
        var areas = new List<MaterialArea>();
        foreach (Node child in materialAreas.GetChildren())
        {
            if (child is MaterialArea area)
            {
                areas.Add(area);
            }
        }
        return areas;
    }

    private List<SpawnArea> GetSpawnAreas()
    {
        var areas = new List<SpawnArea>();
        foreach (Node area in spawnAreas.GetChildren())
        {
            if (area is SpawnArea spawnArea)
            {
                areas.Add(spawnArea);
            }
        }
        return areas;
    }

    private float[,,] GetValueField(){
        // Get all CSG meshes and their transforms
        var csgMeshes = csgCombiner.GetChildren();
        
        // Calculate combined bounding box
        var aabb = csgCombiner.GetAabb();

        // Create 3D array based on bounding box dimensions
        int sizeX = (int)Mathf.Ceil(aabb.Size.X / Map.CHUNK_SIZE+1) * Map.CHUNK_SIZE;
        int sizeY = (int)Mathf.Ceil(aabb.Size.Y / Map.CHUNK_SIZE+1) * Map.CHUNK_SIZE;
        int sizeZ = (int)Mathf.Ceil(aabb.Size.Z / Map.CHUNK_SIZE+1) * Map.CHUNK_SIZE;
        float[,,] valueField = new float[sizeX, sizeY, sizeZ];

        // Check each point in 3D grid
        for (int x = 0; x < sizeX; x++)
        {
            for (int y = 0; y < sizeY; y++)
            {
                for (int z = 0; z < sizeZ; z++)
                {
                    Vector3 point = aabb.Position + new Vector3(x, y, z);
                    bool inside = false;

                    foreach (CsgShape3D csgmesh in csgMeshes.Select(v => (CsgShape3D)v))
                    {
                        if(csgmesh is MapSolidShapeInterface solid)
                        {
                            inside = solid.IsPointInside(point);
                            break;
                        } else {
                            var elements = csgmesh.GetMeshes();
                            Vector3 localPoint = ((Transform3D)elements[0]).AffineInverse() * point;
                            var mesh = (Mesh)elements[1];
                            var aabbMesh = mesh.GetAabb();
                            if (localPoint.X >= aabbMesh.Position.X && localPoint.X <= aabbMesh.Position.X + aabbMesh.Size.X &&
                                localPoint.Y >= aabbMesh.Position.Y && localPoint.Y <= aabbMesh.Position.Y + aabbMesh.Size.Y &&
                                localPoint.Z >= aabbMesh.Position.Z && localPoint.Z <= aabbMesh.Position.Z + aabbMesh.Size.Z)
                            {
                                inside = true;
                                break;
                            }
                        }
                        
                    }

                    valueField[x, y, z] = inside ? 1.0f : 0.0f;
                }
            }
        }

        return valueField;
    }


}
