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
@export var chunk_size:int = 12

var chunk_data = []

func _ready():
	generate()

func generate(seed = 1):
	noise_map.seed = seed
	for x in range(chunks.x):
		for y in range(chunks.y):
			for z in range(chunks.z):
				var chunk_pos = Vector3(x, y, z)
				var value_field = _generate_value_field(chunk_pos)
				var mesh = _create_marched_mesh(value_field)
				var instances = _add_mesh_and_collision(mesh, chunk_pos)
				chunk_data.append({
					"value_field": value_field,
					"mesh": instances["mesh"],
					"collision": instances["collision"],
					"center": chunk_pos * (chunk_size - 1) + Vector3(chunk_size / 2, chunk_size / 2, chunk_size / 2)
				})

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
	collision_shape.position = chunk_pos * (chunk_size - 1)
	static_body.add_child(collision_shape)
	terrain.add_child(mesh_instance)
	return {
		"mesh": mesh_instance,
		"collision": collision_shape
	}

func _remove_chunk(chunk:Dictionary):
	chunk["mesh"].queue_free()
	chunk["collision"].queue_free()


func on_bullet_exploded(explosion_position:Vector3,explosion_radius:float):
	var half_chunk_size = chunk_size / 2

	# Find the 8 closest chunks
	var closest_chunks = []
	for chunk in chunk_data:
		var distance = (chunk["center"] - explosion_position).length()
		closest_chunks.append({"chunk": chunk, "distance": distance})

	closest_chunks.sort_custom(_sort_by_distance)
	closest_chunks = closest_chunks.slice(0, 8)

	# Iterate over the affected chunks and modify the value fields
	for entry in closest_chunks:
		var chunk = entry["chunk"]
		var chunk_center = chunk["center"]
		var chunk_pos = chunk_center - Vector3(half_chunk_size, half_chunk_size, half_chunk_size)
		var value_field = chunk["value_field"]
		
		for x in range(chunk_size):
			for y in range(chunk_size):
				for z in range(chunk_size):
					var voxel_pos = chunk_pos + Vector3(x, y, z)
					if (voxel_pos - explosion_position).length() <= explosion_radius:
						value_field[x][y][z] = -1.0
		
		# Regenerate the chunk
		var mesh = _create_marched_mesh(value_field)
		_remove_chunk(chunk)
		var instances = _add_mesh_and_collision(mesh, chunk_pos)
		chunk["mesh"] = instances["mesh"]
		chunk["collision"] = instances["collision"]

# Helper function to sort chunks by distance
func _sort_by_distance(a, b):
	return a["distance"] < b["distance"]
