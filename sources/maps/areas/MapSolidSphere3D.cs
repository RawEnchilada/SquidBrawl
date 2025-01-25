using Godot;
using System;

namespace Terrain;

[Tool]
public partial class MapSolidSphere3D : CsgSphere3D, MapSolidShapeInterface
{
    public bool IsPointInside(Vector3 point)
    {
        return (point - Position).Length() < Radius;
    }
}