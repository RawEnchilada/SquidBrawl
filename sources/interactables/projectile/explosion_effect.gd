extends Node3D

@onready var emitter = $ExplosionEmitter
@onready var sound_player = $AudioStreamPlayer3D

var explosion_radius:float = 1.0

func _ready():
	(emitter.draw_pass_1 as QuadMesh).size = Vector2(explosion_radius,explosion_radius) * 3
	emitter.emitting = true
	sound_player.connect("finished",Callable(self,"queue_free"))
	sound_player.pitch_scale = randf_range(0.8,1.2)
	sound_player.play()
