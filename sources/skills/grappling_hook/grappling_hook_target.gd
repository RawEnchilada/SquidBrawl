extends Node3D

@export var target:Vector3 = Vector3.ZERO

@onready var hook = $GHook
@onready var rope_mesh = $RopeMesh.mesh as ImmediateMesh

func _ready():
	hook.look_at_from_position(global_position,target, Vector3.DOWN)

func _physics_process(_delta):
	rope_mesh.clear_surfaces()
	rope_mesh.surface_begin(Mesh.PRIMITIVE_LINES, null)
	rope_mesh.surface_add_vertex(to_local(position))
	rope_mesh.surface_add_vertex(to_local(target))
	rope_mesh.surface_end()
