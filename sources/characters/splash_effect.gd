class_name SplashEffect
extends Node3D


@onready var emitter = $GPUParticles3D
@onready var sound_player = $AudioStreamPlayer3D

func _ready():
    emitter.emitting = true
    sound_player.connect("finished",Callable(self,"queue_free"))
    sound_player.pitch_scale = randf_range(0.8,1.2)
    sound_player.play()
