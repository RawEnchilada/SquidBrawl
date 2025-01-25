using Godot;
using System;
using System.Collections.Generic;
using System.Linq;


namespace Terrain;


[Tool]
public partial class Editor : Node3D
{

    [Export]
    string mapName = "default";
    [Export]
    bool save = false;
    [Export]
    bool load = false;

    CsgCombiner3D csgCombiner;
    Node3D materialAreas;
    Map map;
    
	public override void _Ready()
	{
        csgCombiner = GetNode<CsgCombiner3D>("CsgCombiner3D");
        materialAreas = GetNode<Node3D>("MaterialAreas");
    }
    public override void _Process(double delta)
    {
        if (save)
        {
            Map.SaveMapAs(GetValueField(), GetMaterialAreas(), mapName);
            save = false;
        }
        if (load)
        {
            map.LoadMap(mapName);
            load = false;
        }
    }

    private List<MaterialArea> GetMaterialAreas()
    {
        var areas = new List<MaterialArea>();
        foreach (MaterialArea area in materialAreas.GetChildren().Cast<MaterialArea>())
        {
            areas.Add(new MaterialArea
            {
                Size = area.Size,
                GlobalPosition = area.GlobalPosition,
                apply_material = area.apply_material
            });
        }
        return areas;
    }

    private float[,,] GetValueField()
{
    // Get all CSG meshes and their transforms
    var csgMeshes = csgCombiner.GetChildren();
    
    // Calculate combined bounding box
    var aabb = csgCombiner.GetAabb();

    // Create 3D array based on bounding box dimensions
    int sizeX = (int)Mathf.Ceil(aabb.Size.X);
    int sizeY = (int)Mathf.Ceil(aabb.Size.Y);
    int sizeZ = (int)Mathf.Ceil(aabb.Size.Z);
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
                    // Transform point to mesh local space
                    var elements = csgmesh.GetMeshes();
                    Vector3 localPoint = ((Transform3D)elements[0]).AffineInverse() * point;
                    var mesh = (Mesh)elements[1];
                    
                    // TODO - check if point is inside mesh
                    // for now use bounding box
                    var aabbMesh = mesh.GetAabb();
                    if (localPoint.X >= aabbMesh.Position.X && localPoint.X <= aabbMesh.Position.X + aabbMesh.Size.X &&
                        localPoint.Y >= aabbMesh.Position.Y && localPoint.Y <= aabbMesh.Position.Y + aabbMesh.Size.Y &&
                        localPoint.Z >= aabbMesh.Position.Z && localPoint.Z <= aabbMesh.Position.Z + aabbMesh.Size.Z)
                    {
                        inside = true;
                        break;
                    }
                    
                }

                valueField[x, y, z] = inside ? 1.0f : 0.0f;
            }
        }
    }

    return valueField;
}


}
