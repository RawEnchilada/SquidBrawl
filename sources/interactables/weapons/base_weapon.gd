class_name BaseWeapon
extends RigidBody3D

static var WEAPON_COUNT = 0
const BULLET_SCENE = preload("res://sources/interactables/projectile/bullet.tscn")

@export var weapon_name:String = "Weapon"
@export var fire_rate:float = 1.0

@export var bullet_explosion_radius:float = 1.0
@export var bullet_explosion_strength:float = 1.0
@export var bullet_speed:float = 1.0
@export var bullet_gravity:float = 0.0
@export var equipped:bool = false


func _init():
	name = str(GameManager.local_id) + "_Weapon_" + str(WEAPON_COUNT)
	WEAPON_COUNT += 1

func _ready():
	set_multiplayer_authority(GameManager.HOST_ID)
	if(GameManager.local_id != GameManager.HOST_ID):
		set_physics_process(false)
		set_process(false)

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
	equipped = true

func enable_physics():
	freeze = false
	equipped = false
