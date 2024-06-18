class_name BaseSkill
extends Node


var use_rate:float = 4.0

# Returns true if the skill was activated
func activate(player:Player,raycast:RayCast3D)->bool:
	return false

func deactivate():
	pass

# Called every frame when the skill is active, before moving the player with the final velocity
func update(player:Player, delta:float):
	pass
