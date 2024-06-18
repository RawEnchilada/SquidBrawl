class_name Bullet
extends RigidBody3D

static var BULLET_COUNT = 0

signal bullet_exploded(explosion_position:Vector3,explosion_radius:float)

@export var explosion_radius:float = 10.0
@export var explosion_strength:float = 10.0
@export var speed:float = 10.0
@export var gravity:float = 0.0

var direction:Vector3 = Vector3.ZERO

@onready var explosion_area:Area3D = $ExplosionArea
@onready var explosion_emitter:GPUParticles3D = $ExplosionEmitter

func _init():
	name = str(GameManager.local_id) + "_Bullet_" + str(BULLET_COUNT)
	BULLET_COUNT += 1

func _ready():
	gravity_scale = gravity
	((explosion_area.get_child(0) as CollisionShape3D).shape as SphereShape3D).radius = explosion_radius
	(explosion_emitter.draw_pass_1 as QuadMesh).size = Vector2(explosion_radius,explosion_radius)
	set_multiplayer_authority(GameManager.HOST_ID)
	if(GameManager.local_id != GameManager.HOST_ID):
		set_physics_process(false)
		set_process(false)
	GameManager.game_in_progress.register_projectile(self)
	  
func _physics_process(delta):
	var collision = move_and_collide(direction * speed * delta)
	if(collision):
		rpc("explode_remote")
		emit_signal("bullet_exploded",global_position,explosion_radius)
		queue_free()

@rpc("call_local")
func explode_remote():
	var bodies = explosion_area.get_overlapping_bodies()
	for player in bodies:
		var impulse = ((player.global_position+Vector3.UP)-global_position).normalized() * explosion_strength
		player.apply_impulse(impulse)

	explosion_emitter.emitting = true
	explosion_emitter.reparent(GameManager.game_in_progress)
	explosion_emitter.finished.connect(Callable(explosion_emitter,"queue_free"))
