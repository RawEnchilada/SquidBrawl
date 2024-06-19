class_name SpawnArea
extends Node3D

static var spawner_areas = []

const WEAPON_SCENES = [
	preload("res://sources/interactables/weapons/bazooka.tscn"),
	preload("res://sources/interactables/weapons/mortar.tscn"),
]

var random_seed = 0

func _ready():
	spawner_areas.append(self)


static func get_spawn_point(id:int)->SpawnArea:
	if(spawner_areas.size() == 0):
		printerr("There are no spawner areas!")
		return null
	else:
		return spawner_areas[id % spawner_areas.size()]

func get_weapon()->BaseWeapon:
	var weapon = WEAPON_SCENES[random_seed % WEAPON_SCENES.size()].instantiate()
	return weapon
