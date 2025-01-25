class_name Player
extends CharacterBody3D

var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")

signal weapon_cooldown_changed(cooldown:float)
signal skill_cooldown_changed(cooldown:float)
signal weapon_equipped(weapon:BaseWeapon)
signal player_died(player:Player)

@onready var player_model: CharacterModel = $CharacterModel
@onready var interact_area: Area3D = $CameraBase/CameraPivot/InteractArea
@onready var nametag: Label3D = $Label3D
@onready var camera_base: Node3D = $CameraBase
@onready var camera_pivot: Node3D = $CameraBase/CameraPivot
@onready var camera: Camera3D = $CameraBase/CameraPivot/SpringArm3D/Camera3D
@onready var raycast: RayCast3D = $CameraBase/CameraPivot/SpringArm3D/Camera3D/RayCast3D
@onready var weapon_holder: Node3D = $CameraBase/CameraPivot/WeaponHolder
@onready var jumping_audio_player: AudioStreamPlayer3D = $JumpingAudioPlayer


@export var id: int = -1
@export var player_name: String = "WURM"
@export var player_color: Color = Color.WHITE
@export var weapon_type: Enums.WeaponType = Enums.WeaponType.BAZOOKA


func set_authority(value):
	id = value
	set_multiplayer_authority(value)
	if(GameManager.local_id == id):
		GameManager.init_player(self)
		camera.current = true
		set_physics_process(true)
		set_process_input(true)
		collision_layer = 4
		nametag.visible = false
		interact_area.connect("body_entered",Callable(interact_area,"on_interactable_entered"))
		interact_area.connect("body_exited",Callable(interact_area,"on_interactable_exited"))


@export var speed: float = 7.5
@export var jump_velocity: float = 6.0
@export var weapon_cooldown: float = 100.0
@export var skill_cooldown: float = 100.0
@export var equipped_weapon: BaseWeapon = null
var skill: BaseSkill = GrapplingHookSkill.new()


func _ready():
	set_physics_process(false)
	set_process_input(false)
	player_model.set_color(player_color)
	nametag.text = player_name
	if get_window().has_focus():
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if(!GameManager.paused):
		if(event is InputEventMouseMotion):
			camera_pivot.rotate_x(-event.relative.y * Settings.mouse_sensitivity * 0.01)
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI / 2 + 0.1, PI / 2 - 0.1)
			camera_base.rotate_y(-event.relative.x * Settings.mouse_sensitivity * 0.01)

		elif(equipped_weapon && event.is_action_pressed("use_weapon") && weapon_cooldown >= 100.0):
			fire_weapon()

		elif(interact_area.closest_interactable != null && event.is_action_pressed("interact")):
			equip_weapon(interact_area.closest_interactable)
			interact_area.on_interactable_exited(interact_area.closest_interactable)

		elif(event.is_action_pressed("grapple") && skill_cooldown >= 100.0):
			use_skill()
		elif(event.is_action_released("grapple")):
			skill.deactivate()


func use_skill():
	if(skill.activate(self,raycast)):
		skill_cooldown = 0.0

func fire_weapon():
	equipped_weapon.shoot(weapon_holder.global_position,-camera.global_transform.basis.z, id)
	weapon_cooldown = 0.0


func equip_weapon(weapon: BaseWeapon):
	if(equipped_weapon):
		equipped_weapon.drop()
	equipped_weapon = weapon
	weapon.equip(self)
	


func _physics_process(delta:float):
	if(!GameManager.paused):
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
			
		var direction = (camera_base.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var target_x = 0.0
		var target_z = 0.0
		if direction:
			target_x = direction.x * speed
			target_z = direction.z * speed
		
		player_model.turn_to_target(direction,delta)
			
		# Handle ground movement
		if is_on_floor():
			if Input.is_action_just_pressed("jump"):
				velocity.y = jump_velocity
				jumping_audio_player.pitch_scale = randf_range(1.4, 1.8)
				jumping_audio_player.play()

			velocity.x = move_toward(velocity.x, target_x, delta * speed * 10.0)
			velocity.z = move_toward(velocity.z, target_z, delta * speed * 10.0)

		# Handle air control
		else:
			velocity.y -= GRAVITY * delta

			if((target_x > 0 and velocity.x < speed) or 
				(target_x < 0 and velocity.x > -speed)):
				velocity.x = move_toward(velocity.x, target_x, delta * speed)
			if((target_z > 0 and velocity.z < speed) or 
				(target_z < 0 and velocity.z > -speed)):
				velocity.z = move_toward(velocity.z, target_z, delta * speed)


		skill.update(self, delta)

		move_and_slide()

		# Update weapon_cooldown
		if(weapon_cooldown < 100.0 && equipped_weapon != null):
			weapon_cooldown += (100.0/(60.0 / equipped_weapon.fire_rate))*delta
		else:
			weapon_cooldown = 100.0
		emit_signal("weapon_cooldown_changed", weapon_cooldown)

		# Update skill_cooldown
		if(skill_cooldown < 100.0):
			skill_cooldown += (100.0/(60.0 / skill.use_rate))*delta
		else:
			skill_cooldown = 100.0
		emit_signal("skill_cooldown_changed", skill_cooldown)


func get_look_target() -> Vector3:	
	return camera.get_global_transform().origin + camera.get_global_transform().basis.z

@rpc("call_local","any_peer")
func apply_impulse_remote(impulse:Vector3):
	velocity += impulse

func _on_death_area_area_entered(_area:Area3D):
	if(equipped_weapon != null):
		equipped_weapon.drop()
	emit_signal("player_died",self)
