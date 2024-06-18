class_name GrapplingHookSkill
extends BaseSkill

static var hook_scene = preload("res://sources/skills/grappling_hook/grappling_hook_target.tscn")

var is_active = false
var target_position = Vector3.ZERO
var target_length = 0.0
var grappling_strength = 3.0
var hook_node:Node3D = null

func _ready():
	use_rate = 4.0


# Returns true if the skill was activated
func activate(player:Player,raycast:RayCast3D):
	if(!is_active && raycast.is_colliding()):
		is_active = true
		target_position = raycast.get_collision_point()
		target_length = (target_position - player.global_position).length()+1.0
		hook_node = hook_scene.instantiate()
		GameManager.game_in_progress.add_child(hook_node)
		hook_node.global_position = target_position
		return true
	return false

func deactivate():
	if(is_active):
		is_active = false
		hook_node.queue_free()

# Called every frame when the skill is active, before moving the player with the final velocity
func update(player:Player, delta:float):
	if(is_active):
		var direction_to_target = (target_position - player.global_position).normalized()
		var distance_to_target = (target_position - player.global_position).length()
		
		if(distance_to_target > target_length):
			var st_dot = direction_to_target.dot(direction_to_target)
			var velocity_dot = player.velocity.dot(direction_to_target)
			var velocity_parallel = (velocity_dot / st_dot) * direction_to_target
			var cancelling_vector = -velocity_parallel

			player.velocity += cancelling_vector
		player.velocity += direction_to_target * grappling_strength * player.speed * delta

		update_rope(target_position,player.global_position)
		



func update_rope(node_position:Vector3,player_position:Vector3):
	if(hook_node != null):
		var rope_mesh = hook_node.get_node("RopeMesh").mesh as ImmediateMesh
		rope_mesh.clear_surfaces()
		rope_mesh.surface_begin(Mesh.PRIMITIVE_LINES, null)
		rope_mesh.surface_add_vertex(hook_node.to_local(node_position))
		rope_mesh.surface_add_vertex(hook_node.to_local(player_position))
		rope_mesh.surface_end()
