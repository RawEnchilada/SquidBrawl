extends Node3D

var move_speed := 5.0
var free_camera_enabled := false

@onready var camera: Camera3D = $Camera3D


func _input(event):
	if(event is InputEventMouseMotion):
		rotate_x(-event.relative.y * Settings.mouse_sensitivity * 0.01)
		rotation.x = clamp(rotation.x, -PI / 2, PI / 2)
		camera.rotate_y(-event.relative.x * Settings.mouse_sensitivity * 0.01)
	elif event.is_action_pressed("free_camera"):
		free_camera_enabled = !free_camera_enabled
		if free_camera_enabled:
			GameManager.paused = true
			camera.current = false
		else:
			GameManager.paused = false
			camera.current = true
				

func _physics_process(delta):
	if free_camera_enabled:
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var up_dir = 1.0 if Input.is_action_pressed("jump") else 0.0
		var down_dir = 1.0 if Input.is_action_pressed("dodge") else 0.0

		var direction = Vector3(input_dir.x, up_dir-down_dir, input_dir.y)

		global_position += direction * move_speed * delta
