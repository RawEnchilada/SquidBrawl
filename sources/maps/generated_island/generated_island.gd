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

@export var chunks = Vector3(3, 1, 3)
@export var chunk_size = 16

var chunk_data = {}

func _ready():
	generate()

func generate(seed = 1):
	noise_map.seed = seed
	for x in range(chunks.x):
		for y in range(chunks.y):
			for z in range(chunks.z):
				var chunk = _create_chunk(Vector3(x, y, z))
				chunk_data[Vector3(x, y, z)] = chunk
				terrain.add_child(chunk)

func _create_chunk(chunk_pos: Vector3):
	var mesh_instance = MeshInstance3D.new()
	var st = MarchingCubes.apply_marching_cubes(noise_map, chunk_pos*chunk_size, chunk_size)
	st.set_material(GROUND_MATERIAL)
	var mesh = st.commit()
	mesh_instance.mesh = mesh
	mesh_instance.position = chunk_pos * chunk_size

	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(collision_shape)

	return mesh_instance







func on_bullet_exploded(explosion_position:Vector3,explosion_radius:float):
	pass
