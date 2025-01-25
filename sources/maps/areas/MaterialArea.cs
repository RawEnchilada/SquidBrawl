using Godot;

namespace Terrain;

[Tool]
public partial class MaterialArea : CsgBox3D
{
    [Export(PropertyHint.File)]
    public string apply_material;
}