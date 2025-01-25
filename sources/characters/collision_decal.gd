class_name SplatterDecal
extends Decal

static var splatters = []
const MAX_SPLATTERS = 100
static var splatter_scene = preload("res://sources/characters/collision_decal.tscn")

static func create_splatter(parent:Node3D,pos:Vector3,color:Color,rotation:Vector3 = Vector3(0.0,0.0,0.0))->void:
	var splatter:SplatterDecal = splatter_scene.instantiate()
	splatter.set_color(color)
	parent.add_child(splatter)
	splatter.global_position = pos
	splatter.global_rotation_degrees = rotation
	splatters.append(splatter)
	if splatters.size() > MAX_SPLATTERS:
		splatters[0].queue_free()
		splatters.pop_front()

func _ready() -> void:
	var splatter_size = randf_range(0.5,2.0)
	size = Vector3(splatter_size,splatter_size,splatter_size)
	var splatter_rotation = randf_range(0.0,360.0)
	rotation_degrees = Vector3(0.0,splatter_rotation,0.0)

func set_color(color:Color)->void:
	modulate = color
