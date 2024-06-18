class_name CharacterModel
extends Node3D

signal model_hit(damage:int)

@export var skeleton:Skeleton3D = null
@export var skeletonik:SkeletonIK3D = null
@export var head_ik_target:Node3D = null
@export var right_hand_target:Node3D = null
@export var animation_player:AnimationPlayer = null

@export var collision_layer:int = 4 # b00000000_00000000_00000000_00000100
@export var collision_mask:int = 3  # b00000000_00000000_00000000_00000011

@onready var wurm_body:MeshInstance3D = $Armature/Skeleton3D/Sphere

var is_ragdoll = false

func _ready():
	skeletonik.start()
	
	for bones in skeleton.get_children():
		if(bones is PhysicalBone3D):
			bones.collision_layer = collision_layer
			bones.collision_mask = collision_mask


func look_at_target(target:Vector3):
	head_ik_target.look_at(target,Vector3.UP)

func turn_to_target(target:Vector3,delta:float):
	var next_step_to_target = (global_transform.basis * Vector3.BACK).lerp(-target, delta*10.0)
	look_at(global_position-next_step_to_target)
	rotation.x = 0.0
	rotation.z = 0.0

func enter_ragdoll():
	skeleton.physical_bones_start_simulation()
	skeletonik.stop()
	is_ragdoll = true

func exit_ragdoll():
	skeleton.physical_bones_stop_simulation()
	skeletonik.start()
	is_ragdoll = false

func toggle_ragdoll():
	if(is_ragdoll):
		exit_ragdoll()
	else:
		enter_ragdoll()


func emit_model_hit(damage:int):
	emit_signal("model_hit",damage)


func set_color(color:Color):
	wurm_body.get_surface_override_material(0).albedo_color = color