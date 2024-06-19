class_name BaseSkill
extends Node


var use_rate:float = 4.0

# Returns true if the skill was activated
func activate(_player:Player,_raycast:RayCast3D)->bool:
	return false

func deactivate():
	pass

# Called every frame when the skill is active, before moving the player with the final velocity
func update(_player:Player, _delta:float):
	pass
