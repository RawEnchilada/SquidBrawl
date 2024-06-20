extends Node3D

@export var move_speed:float = 5.0
@export var free_camera_enabled:bool = true

@onready var camera_base: Node3D = $CameraBase
@onready var camera: Camera3D = $CameraBase/Camera3D


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if(!GameManager.paused):
		if(event is InputEventMouseMotion):
			camera.rotate_x(-event.relative.y * Settings.mouse_sensitivity * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, -PI / 2, PI / 2)
			camera_base.rotate_y(-event.relative.x * Settings.mouse_sensitivity * 0.01)
				

func _physics_process(delta):
	if free_camera_enabled && !GameManager.paused:
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var up_dir = 1.0 if Input.is_action_pressed("jump") else 0.0
		var down_dir = 1.0 if Input.is_action_pressed("dodge") else 0.0
		var direction = (camera_base.transform.basis * Vector3(input_dir.x, up_dir-down_dir, input_dir.y)).normalized()


		global_position += direction * move_speed * delta
