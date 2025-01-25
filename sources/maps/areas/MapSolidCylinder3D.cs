using Godot;
using System;

namespace Terrain;

[Tool]
public partial class MapSolidCylinder3D : CsgCylinder3D, MapSolidShapeInterface
{
    public bool IsPointInside(Vector3 point)
    {
        return (point - Position).Length() < Radius && point.Y > Position.Y && point.Y < Position.Y + Height;
    }
}