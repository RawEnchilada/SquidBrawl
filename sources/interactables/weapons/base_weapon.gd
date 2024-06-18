class_name BaseWeapon
extends RigidBody3D

const BULLET_SCENE = preload("res://sources/interactables/projectile/bullet.tscn")

@export var weapon_name:String = "Weapon"
@export var fire_rate:float = 1.0

@export var bullet_explosion_radius:float = 1.0
@export var bullet_explosion_strength:float = 1.0
@export var bullet_speed:float = 1.0
@export var bullet_gravity:float = 0.0

func get_interaction_hint():
	return "Press E to equip " + weapon_name


func shoot(from:Vector3, direction:Vector3):
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = direction
	bullet.position = from

	bullet.explosion_radius = bullet_explosion_radius
	bullet.explosion_strength = bullet_explosion_strength
	bullet.speed = bullet_speed
	bullet.gravity = bullet_gravity
	GameManager.game_in_progress.synced_node.add_child(bullet)
	

func disable_physics():
	freeze = true

func enable_physics():
	freeze = false
