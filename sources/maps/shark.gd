class_name Shark
extends Node3D

var _current_angle = 0.0

@export
var speed = 1.0
@export
var radius = 1.0


func _process(delta: float) -> void:
    global_position = Vector3(
        radius * cos(_current_angle),
        0.0,
        radius * sin(_current_angle)
    )
    
    _current_angle += delta * speed

    rotation = Vector3(0.0, -_current_angle, 0.0)