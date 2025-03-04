class_name Bullet
extends RigidBody3D

static var BULLET_COUNT = 0
const BULLET_SCENE = preload("res://sources/interactables/projectile/bullet.tscn")

signal bullet_exploded(explosion_position:Vector3,explosion_radius:float)

@export var explosion_radius:float = 10.0
@export var explosion_strength:float = 10.0
@export var speed:float = 10.0
@export var gravity:float = 0.0
@export var direction:Vector3 = Vector3.ZERO
@export var ignore_player:int = 0
@export var bounce:int = 0
@export var cluster:int = 0

var owner_id:int = 0
var _force:Vector3 = Vector3.ZERO

@onready var explosion_area:Area3D = $ExplosionArea
@onready var synchronizer:MultiplayerSynchronizer = $MultiplayerSynchronizer

func _ready():
	name = "Bullet_" + str(BULLET_COUNT)
	BULLET_COUNT += 1
	((explosion_area.get_child(0) as CollisionShape3D).shape as SphereShape3D).radius = explosion_radius
	_force = direction * speed
	set_multiplayer_authority(GameManager.HOST_ID)
	if(!GameManager.is_host()):
		set_physics_process(false)
		set_process(false)
	  
func _physics_process(delta):
	_force += Vector3.UP * gravity * 0.2
	var collision = move_and_collide(_force * delta)
	look_at(global_position + _force.normalized(), Vector3.UP)
	if(collision && ((collision.get_collider() is Player && collision.get_collider().id != ignore_player) || collision.get_collider() is not Player)):
		if bounce > 0:
			bounce -= 1
			_force = _force - 1.5 * _force.dot(collision.get_normal()) * collision.get_normal()
		elif(cluster > 0):
			for i in range(cluster):
				Bullet.create_bullet(
					(collision.get_normal()+Vector3.FORWARD).rotated(Vector3.UP, 2.0*PI*i/cluster),
					global_position,
					explosion_radius,
					explosion_strength,
					speed/2.0,
					gravity,
					bounce,
					0,
					owner_id
				)
			queue_free()
		else:
			var bodies = explosion_area.get_overlapping_bodies()
			for body in bodies:
				var distance = body.global_position.distance_to(global_position)
				var impulse_distance_falloff = 2.0 - min(distance / explosion_radius, 1.0)
				var impulse = ((body.global_position+Vector3.UP)-global_position).normalized() * impulse_distance_falloff * explosion_strength
				if body is Player:
					if(body.id == owner_id):
						body.rpc_id(body.id,"apply_impulse_remote",impulse)
					else:
						body.rpc_id(body.id,"apply_impulse_remote",impulse*2.0)
				elif body is FloatableBody3D:
					body.apply_impulse(impulse*2.0)
			GameManager.game_in_progress.rpc("create_explosion_at_remote",global_position,explosion_radius)
			queue_free()
	elif(global_position.length() > 1000.0):
		queue_free()



static func create_bullet(
	bullet_direction:Vector3,
	from:Vector3,
	bullet_explosion_radius:float,
	bullet_explosion_strength:float,
	bullet_speed:float,
	bullet_gravity:float,
	bullet_bounce:int,
	bullet_cluster:int,
	player_id:int
	):
	var bullet = BULLET_SCENE.instantiate()
	bullet.direction = bullet_direction
	bullet.position = from
	bullet.explosion_radius = bullet_explosion_radius
	bullet.explosion_strength = bullet_explosion_strength
	bullet.speed = bullet_speed
	bullet.gravity = bullet_gravity
	bullet.bounce = bullet_bounce
	bullet.cluster = bullet_cluster
	bullet.ignore_player = player_id
	bullet.owner_id = player_id
	GameManager.game_in_progress.synced_node.add_child(bullet)
