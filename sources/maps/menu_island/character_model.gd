class_name RagdollCharacterModel
extends Node3D

@onready
var body: MeshInstance3D = $Armature_003/Skeleton3D/Cylinder_007
@onready
var tentacles: MeshInstance3D = $Armature_003/Skeleton3D/Cylinder_009
@onready
var eyes: MeshInstance3D = $Armature_003/Skeleton3D/Cylinder_008/Cylinder_008

func set_color(color: Color)->void:
	body.get_surface_override_material(0).albedo_color = color
	eyes.get_surface_override_material(0).albedo_color = color
	tentacles.get_surface_override_material(0).albedo_color = color