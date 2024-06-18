class_name Bullet
extends RigidBody3D

@export var explosion_radius:float = 10.0
@export var explosion_strength:float = 10.0
@export var speed:float = 10.0
@export var gravity:float = 0.0

var direction:Vector3 = Vector3.ZERO

@onready var explosion_area:Area3D = $ExplosionArea
@onready var explosion_emitter:GPUParticles3D = $ExplosionEmitter


func _ready():
    gravity_scale = gravity
    ((explosion_area.get_child(0) as CollisionShape3D).shape as SphereShape3D).radius = explosion_radius
    (explosion_emitter.draw_pass_1 as QuadMesh).size = Vector2(explosion_radius,explosion_radius)
      
func _physics_process(delta):
    var collision = move_and_collide(direction * speed * delta)
    if(collision):
        explode()
        queue_free()

func explode():
    var bodies = explosion_area.get_overlapping_bodies()
    for player in bodies:
        var impulse = ((player.global_position+Vector3.UP)-global_position).normalized() * explosion_strength
        player.apply_impulse(impulse)

    explosion_emitter.emitting = true
    explosion_emitter.reparent(GameManager.game_in_progress)
    explosion_emitter.finished.connect(Callable(explosion_emitter,"queue_free"))
