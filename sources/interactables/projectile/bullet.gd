class_name Bullet
extends RigidBody3D

static var BULLET_COUNT = 0

signal bullet_exploded(explosion_position:Vector3,explosion_radius:float)

@export var explosion_radius:float = 10.0
@export var explosion_strength:float = 10.0
@export var speed:float = 10.0
@export var gravity:float = 0.0
@export var direction:Vector3 = Vector3.ZERO
@export var ignore_player:int = 0

var _force:Vector3 = Vector3.ZERO

@onready var explosion_area:Area3D = $ExplosionArea
@onready var synchronizer:MultiplayerSynchronizer = $MultiplayerSynchronizer

func _ready():
	name = "Bullet_" + str(BULLET_COUNT)
	BULLET_COUNT += 1
	((explosion_area.get_child(0) as CollisionShape3D).shape as SphereShape3D).radius = explosion_radius
	set_multiplayer_authority(GameManager.HOST_ID)
	if(!GameManager.is_host()):
		set_physics_process(false)
		set_process(false)
	  
func _physics_process(delta):
	_force = _force + Vector3.UP * gravity * 0.2
	var collision = move_and_collide((direction * speed + _force) * delta)
	if(collision && ((collision.get_collider() is Player && collision.get_collider().id != ignore_player) || collision.get_collider() is StaticBody3D)):
		var bodies = explosion_area.get_overlapping_bodies()
		for player in bodies:
			var impulse = ((player.global_position+Vector3.UP)-global_position).normalized() * explosion_strength
			player.rpc_id(player.id,"apply_impulse_remote",impulse)
		GameManager.game_in_progress.rpc("create_explosion_at_remote",global_position,explosion_radius)
		queue_free()

