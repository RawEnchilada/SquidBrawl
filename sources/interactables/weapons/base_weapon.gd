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
@export var bullet_bounce:int = 0
@export var bullet_cluster:int = 0
@export var projectile_count:int = 1
@export var accuracy:float = 1.0
@export var equipped:bool = false
var equipped_by:Node3D = null

func _ready():
	name = weapon_name + "_w_" + str(WEAPON_COUNT)
	WEAPON_COUNT += 1
	set_multiplayer_authority(GameManager.HOST_ID)
	if(!GameManager.is_host()):
		set_physics_process(false)
		set_process(false)

func _process(_delta):
	if(equipped_by != null):
		global_position = equipped_by.global_position
		global_rotation = equipped_by.global_rotation


func get_interaction_hint():
	return "E to equip " + weapon_name


func shoot(from:Vector3, direction:Vector3, player_id:int):
	rpc_id(GameManager.HOST_ID,"shoot_remote", from, direction, player_id)

@rpc("any_peer","call_local")
func shoot_remote(from:Vector3, direction:Vector3, player_id:int):
	var offset:float = 1.0 - accuracy
	for i in range(projectile_count):
		var adjusted_direction = direction.rotated(Vector3.UP, randf_range(-offset,offset))
		Bullet.create_bullet(
			adjusted_direction,
			from,
			bullet_explosion_radius,
			bullet_explosion_strength,
			bullet_speed,
			bullet_gravity,
			bullet_bounce,
			bullet_cluster,
			player_id
		)
	

func equip(owned_by:Player):
	rpc("set_is_equipped_remote", owned_by.id)

func drop():
	rpc("set_is_equipped_remote", -1)


@rpc("call_local","any_peer")
func set_is_equipped_remote(player_id:int):
	if(player_id == -1):
		freeze = false
		equipped_by = null
		equipped = false
		player_id = GameManager.HOST_ID
	else:
		var player = GameManager.game_in_progress.synced_node.get_node(str(player_id))
		freeze = true
		equipped_by = player.weapon_holder
		equipped = true
	set_multiplayer_authority(player_id)
	if(GameManager.local_id == player_id):
		set_physics_process(true)
		set_process(true)
	else:
		set_physics_process(false)
		set_process(false)
