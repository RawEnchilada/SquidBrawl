class_name CharacterModel
extends Node3D

signal model_hit(damage:int)

@export var right_hand_target:Node3D = null

@export var collision_layer:int = 4 # b00000000_00000000_00000000_00000100
@export var collision_mask:int = 3  # b00000000_00000000_00000000_00000011

@onready
var body: MeshInstance3D = $Armature/Skeleton3D/Cylinder
@onready
var eyes: MeshInstance3D = $Armature/Skeleton3D/Cylinder_001/Cylinder_001

func turn_to_target(target:Vector3,delta:float):
	var next_step_to_target = (global_transform.basis * Vector3.BACK).lerp(-target, delta*10.0)
	look_at(global_position-next_step_to_target*1.01)
	rotation.x = 0.0
	rotation.z = 0.0


func set_color(color: Color)->void:
	body.get_surface_override_material(0).albedo_color = color
	eyes.get_surface_override_material(0).albedo_color = color