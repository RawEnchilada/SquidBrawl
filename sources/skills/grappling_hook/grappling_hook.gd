class_name GrapplingHookSkill
extends BaseSkill

static var hook_scene = preload("res://sources/skills/grappling_hook/grappling_hook_target.tscn")

var is_active = false
var target_position = Vector3.ZERO
var target_length = 0.0
var grappling_strength = 3.0
var hook_node:Node3D = null

var max_time:float = 2.5
var time:float = 0.0

func _ready():
	use_rate = 6.0


# Returns true if the skill was activated
func activate(player:Player,raycast:RayCast3D):
	if(!is_active && raycast.is_colliding()):
		is_active = true
		target_position = raycast.get_collision_point()
		target_length = (target_position - player.global_position).length()+1.0
		hook_node = hook_scene.instantiate()
		hook_node.position = target_position+raycast.get_collision_normal()*0.2
		hook_node.target = player.global_position
		GameManager.game_in_progress.synced_node.add_child(hook_node)
		time = 0
		return true
	return false

func deactivate():
	if(is_active):
		is_active = false
		hook_node.queue_free()

# Called every frame when the skill is active, before moving the player with the final velocity
func update(player:Player, delta:float):
	if(is_active):
		time += delta
		if(time > max_time):
			deactivate()
		var direction_to_target = (target_position - player.global_position).normalized()
		var distance_to_target = (target_position - player.global_position).length()
		
		if(distance_to_target > target_length):
			var st_dot = direction_to_target.dot(direction_to_target)
			var velocity_dot = player.velocity.dot(direction_to_target)
			var velocity_parallel = (velocity_dot / st_dot) * direction_to_target
			var cancelling_vector = -velocity_parallel

			player.velocity += cancelling_vector
		player.velocity += direction_to_target * grappling_strength * player.speed * delta
		hook_node.target = player.global_position
