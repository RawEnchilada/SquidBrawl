using Godot;
using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Linq;
using System.Data;


namespace Terrain;

[Tool]
public partial class Editor : Node3D
{
    const string mapsFolder = "./maps/";

    static PackedScene mapScene = ResourceLoader.Load<PackedScene>("res://sources/maps/map.tscn");

    [Export]
    string mapName = "default";
    [Export]
    public int seed;
    [Export]
    public Vector3 chunks = new(8, 6, 8);

    [Export]
    bool generate = false;

    Node3D meshContainer;
    Node3D materialAreas;
    Node3D spawnAreas;
    Map map = null;
    
	public override void _Ready()
	{
        if(!Engine.IsEditorHint()){
            materialAreas = GetNode<Node3D>("MaterialAreas");
            spawnAreas = GetNode<Node3D>("SpawnAreas");
            SaveMapAs(seed, chunks, GetMaterialAreas(), GetSpawnAreas(), mapName);
            GetTree().Quit();
        }
    }

    public override void _Process(double delta){
        if(generate){
            generate = false;
            if(map == null){
                map = mapScene.Instantiate<Map>();
                AddChild(map);
            }
            map.seed = seed;
            map.chunks = chunks;
            map.generate = true;
        }
    }

    public static void SaveMapAs(int seed, Vector3 chunks, List<MaterialArea> materialAreas, List<SpawnArea> spawnAreas, string mapname)
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
            {"seed", seed},
            {"chunks", chunks},
            {"materialAreas", materialAreasSerialized},
            {"spawnAreas", spawnAreasSerialized}
        };
        GD.Print("Serialized "+materialAreas.Count+" material areas and "+spawnAreas.Count+" spawn areas to "+mapname+".map");

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
