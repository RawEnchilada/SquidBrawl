using Godot;

namespace Terrain;

interface MapSolidShapeInterface {
    
    public bool IsPointInside(Vector3 point);
}