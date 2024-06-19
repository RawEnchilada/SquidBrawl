extends Node3D

const PALM_SCENE = preload("res://sources/maps/assets/trees/palm.glb")
const PLANT01_SCENE = preload("res://sources/maps/assets/trees/plant01.glb")
const PLANT02_SCENE = preload("res://sources/maps/assets/trees/plant02.glb")
const PLANT03_SCENE = preload("res://sources/maps/assets/trees/plant03.glb")

const GROUND_MATERIAL = preload("res://sources/shaders/ground.tres")

@export var plant_noise_map:FastNoiseLite = null
@export var noise_map: FastNoiseLite = null

@onready var terrain: Node3D = $Terrain
@onready var static_body: StaticBody3D = $StaticBody3D

@export var chunks = Vector3(8, 6, 8)
@export var chunk_size = 12

var chunk_data = {}

func _ready():
	generate()

func generate(seed = 1):
	noise_map.seed = seed
	for x in range(chunks.x):
		for y in range(chunks.y):
			for z in range(chunks.z):
				var chunk_pos = Vector3(x, y, z)
				var value_field = _generate_value_field(chunk_pos)
				chunk_data[chunk_pos] = value_field
				var mesh = _create_marched_mesh(value_field)
				_add_mesh_and_collision(mesh, chunk_pos)

func _generate_value_field(chunk_pos: Vector3) -> Array:
	var tensor = []
	tensor.resize(chunk_size)
	for x in range(chunk_size):
		var matrix = []
		matrix.resize(chunk_size)
		tensor[x] = matrix
		for y in range(chunk_size):
			var arr = []
			arr.resize(chunk_size)
			tensor[x][y] = arr
			for z in range(chunk_size):
				# Check if the current chunk is at the outer boundary
				if chunk_pos.x == 0 and x == 0 or chunk_pos.x == chunks.x - 1 and x == chunk_size - 1 or \
				   chunk_pos.y == 0 and y == 0 or chunk_pos.y == chunks.y - 1 and y == chunk_size - 1 or \
				   chunk_pos.z == 0 and z == 0 or chunk_pos.z == chunks.z - 1 and z == chunk_size - 1:
					tensor[x][y][z] = -1.0
				else:
					tensor[x][y][z] = noise_map.get_noise_3d(chunk_pos.x * (chunk_size - 1) + x, chunk_pos.y * (chunk_size - 1) + y, chunk_pos.z * (chunk_size - 1) + z)
	return tensor

func _create_marched_mesh(tensor:Array) -> ArrayMesh:	
	var st = MarchingCubes.apply_marching_cubes(tensor, chunk_size)
	st.set_material(GROUND_MATERIAL)
	return st.commit()

func _add_mesh_and_collision(mesh:ArrayMesh,chunk_pos: Vector3):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.position = chunk_pos * (chunk_size - 1)

	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)
	terrain.add_child(mesh_instance)
	return mesh_instance





func on_bullet_exploded(explosion_position:Vector3,explosion_radius:float):
	pass
