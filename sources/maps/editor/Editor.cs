using Godot;
using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Linq;
using System.Data;


namespace Terrain;


public partial class Editor : Node3D
{
    const string mapsFolder = "./maps/";

    [Export]
    string mapName = "default";
    [Export]
    bool save = false;

    Node3D meshContainer;
    Node3D materialAreas;
    Node3D spawnAreas;
    
	public override void _Ready()
	{
        meshContainer = GetNode<Node3D>("Mesh");
        materialAreas = GetNode<Node3D>("MaterialAreas");
        spawnAreas = GetNode<Node3D>("SpawnAreas");
        if (save)
        {
            SaveMapAs(GetValueFieldFromMesh(), GetMaterialAreas(), GetSpawnAreas(), mapName);
        }
        GetTree().Quit();
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

        if(terrainTensor.GetLength(0) % Map.CHUNK_SIZE > 0 || terrainTensor.GetLength(1) % Map.CHUNK_SIZE > 0 || terrainTensor.GetLength(2) % Map.CHUNK_SIZE > 0){
            GD.Print("Field dimensions are not divisible by "+Map.CHUNK_SIZE+", aborted saving.");
            return;
        }

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
            GD.Print("Field is empty, aborted saving. Do you have a static collision shape in the scene?");
            return;
        }else{
            GD.Print("Field is looking good with "+solid_count+" solid points.");
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

    private float[,,] GetValueFieldFromMesh(){
        var aabb = meshContainer.GetNode<CsgBox3D>("AABB");
        var startingPosition = aabb.Position - aabb.Size/2.0f;
        var endPosition = aabb.Position + aabb.Size / 2.0f;
        var size = endPosition - startingPosition;
        GD.Print("Bounding box is from "+aabb.Position + " to "+endPosition);
        if(startingPosition.X < 0 || startingPosition.Y < 0 || startingPosition.Z < 0){
            GD.PrintErr("Bounding box has negative points, please move your MeshInstance to positive coordinates!");
        }

        int sizeX = (int)Mathf.Ceil(size.X / Map.CHUNK_SIZE+1) * Map.CHUNK_SIZE;
        int sizeY = (int)Mathf.Ceil(size.Y / Map.CHUNK_SIZE+1) * Map.CHUNK_SIZE;
        int sizeZ = (int)Mathf.Ceil(size.Z / Map.CHUNK_SIZE+1) * Map.CHUNK_SIZE;
        float[,,] valueField = new float[sizeX, sizeY, sizeZ];

        for (int x = 0; x < sizeX; x++)
        {
            for (int y = 0; y < sizeY; y++)
            {
                for (int z = 0; z < sizeZ; z++)
                {
                    Vector3 point = startingPosition + new Vector3(x, y, z);
                    bool inside = IsPointInsideConvex(point);

                    valueField[x, y, z] = inside ? 1.0f : -1.0f;
                }
            }
        }
        return valueField;
    }


    public bool IsPointInsideConvex(Vector3 point)
    {
        var spaceState = GetWorld3D().DirectSpaceState;
        var query = new PhysicsRayQueryParameters3D
        {
            From = point,
            To = Vector3.Up * 1000,
            HitFromInside = true
        };
        var result = spaceState.IntersectRay(query);
        if (result != null && result.ContainsKey("normal"))
        {
            Vector3 normal = (Vector3)result["normal"];

            // The normal will be Vector3.Zero in case of a collision from inside.
            if (normal.IsEqualApprox(Vector3.Zero))
            {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }


}
