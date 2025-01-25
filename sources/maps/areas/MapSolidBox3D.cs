using Godot;
using System;

namespace Terrain;

[Tool]
public partial class MapSolidBox3D : CsgBox3D, MapSolidShapeInterface
{
    public bool IsPointInside(Vector3 point)
    {
        return (Position.X < point.X && Position.X + Size.X > point.X &&
                Position.Y < point.Y && Position.Y + Size.Y > point.Y &&
                Position.Z < point.Z && Position.Z + Size.Z > point.Z);
    }
}