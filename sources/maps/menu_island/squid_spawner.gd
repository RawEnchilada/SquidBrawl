extends Node3D


var squid_scene: PackedScene = preload("res://sources/maps/menu_island/ragdoll_squid.tscn")

func _ready() -> void:
	spawn_squid()

func spawn_squid()->void:
	var squid_instance:RagdollSquid = squid_scene.instantiate()
	add_child(squid_instance)
	var random_color := Color(randf(),randf(),randf(),1)
	squid_instance.set_color(random_color)
	var random_rotation = Vector3((randf()*2-1.0),(randf()*2-1.0),(randf()*2-1.0)).normalized()
	squid_instance.global_rotate(random_rotation, randf()*2*PI)
	squid_instance.apply_central_impulse(Vector3(randf()*0.4-0.25,randf()*0.5+0.5,-1)*20)

func _physics_process(_delta: float) -> void:
	if get_child_count() < 10 and not is_queued_for_deletion():
		spawn_squid()