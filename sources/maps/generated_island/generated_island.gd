extends Node3D

const PALM_SCENE = preload("res://sources/maps/assets/trees/palm.glb")
const PLANT01_SCENE = preload("res://sources/maps/assets/trees/plant01.glb")
const PLANT02_SCENE = preload("res://sources/maps/assets/trees/plant02.glb")
const PLANT03_SCENE = preload("res://sources/maps/assets/trees/plant03.glb")

const GROUND_MATERIAL = preload("res://sources/shaders/ground.tres")

@export var plant_noise_map:FastNoiseLite = null
@export var cell_noise_map:FastNoiseLite = null
@export var noise_map:FastNoiseLite = null

# Used for masking the heightmap during generation to allow a smooth transition into the water on the edges of the island.
@export var island_radius:int = 96
@export var max_height:float = 10.0

@onready var terrain:MeshInstance3D = $Terrain
@onready var collision_shape:CollisionShape3D = $StaticBody3D/CollisionShape3D

func _ready():
    generate()

func generate(seed = 1):
    noise_map.seed = seed
    cell_noise_map.seed = seed
    plant_noise_map.seed = seed
    var mesh = ArrayMesh.new()
    var surface_tool = SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    surface_tool.set_material(GROUND_MATERIAL)

    var size = island_radius * 2
    var half_size = size / 2

    for x in range(size):
        for y in range(size):
            var height = get_height(x, y)
            var vertex = Vector3(x - half_size, height, y - half_size)
            surface_tool.add_vertex(vertex)

    # Generate the island mesh based on heightmap
    for x in range(size - 1):
        for y in range(size - 1):
            var i = x + y * size
            surface_tool.add_index(i)
            surface_tool.add_index(i + size)
            surface_tool.add_index(i + 1)

            surface_tool.add_index(i + 1)
            surface_tool.add_index(i + size)
            surface_tool.add_index(i + size + 1)

    surface_tool.generate_tangents()
    mesh = surface_tool.commit()
    terrain.mesh = mesh
    collision_shape.shape = mesh.create_trimesh_shape()
    
    place_plants()

func get_height(x, y):
    var height = (noise_map.get_noise_2d(x, y)+1.0)*(cell_noise_map.get_noise_2d(x, y)+1.0)/2.0
    var edge_distance = Vector2(x - island_radius, y - island_radius).length()
    var edge_falloff = clamp((island_radius - edge_distance) / island_radius, 0, 0.5)*2.0
    return height * edge_falloff * max_height # Adjust the multiplier to scale height

func place_plants():
    var size = island_radius*2
    for x in range(size):
        for y in range(size):
            var plant_probability = (plant_noise_map.get_noise_2d(x, y)/2.0+0.5)
            var terrain_height = get_height(x, y)
            if plant_probability > 0.9 and terrain_height > 0.1:
                var plant = get_random_plant(x,y)
                var plant_instance = plant.instantiate()
                plant_instance.global_transform.origin = Vector3(x - island_radius, terrain_height, y - island_radius)
                add_child(plant_instance)

func get_random_plant(x:int,y:int):
    var plants = [PALM_SCENE, PLANT01_SCENE, PLANT02_SCENE, PLANT03_SCENE]
    var weight = floor((cell_noise_map.get_noise_2d(x, y)/2.0+0.5)*plants.size())
    return plants[weight]



# Minimum distance between vertices after displacement
var min_vertex_distance : float = 0.1

# Function to destroy part of the mesh
func destroy_terrain(destruction_point: Vector3, radius: float) -> void:
    var surfaces = terrain.mesh.get_surface_count()

    
    for surface_index in range(surfaces):
        var surface_tool = SurfaceTool.new()
        surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
        surface_tool.set_material(GROUND_MATERIAL)
        
        var arrays = terrain.mesh.surface_get_arrays(surface_index)
        var vertices = arrays[ArrayMesh.ARRAY_VERTEX]

        var displaced_vertices = []
        var modified = false
        var size = vertices.size()
        
        for j in range(size):
            var vertex = vertices[j]
            var distance = vertex.distance_to(destruction_point)
            
            if distance < radius:
                modified = true
                # Push the vertex away from the destruction point
                var direction = (vertex - destruction_point).normalized()
                var new_vertex = vertex + direction * distance
                
                # Check if the new vertex is too close to any displaced vertex
                var too_close = false
                for displaced_vertex in displaced_vertices:
                    if new_vertex.distance_to(displaced_vertex) < min_vertex_distance:
                        too_close = true
                        break
                
                displaced_vertices.append(new_vertex)
                surface_tool.add_vertex(new_vertex)
            else:
                surface_tool.add_vertex(vertex)
        
        if modified:
            # Generate the island mesh based on heightmap
            for i in range(size - 1):
                surface_tool.add_index(i)
                surface_tool.add_index(i + island_radius * 2)
                surface_tool.add_index(i + 1)

                surface_tool.add_index(i + 1)
                surface_tool.add_index(i + island_radius * 2)
                surface_tool.add_index(i + island_radius * 2 + 1)
            surface_tool.generate_tangents()
            terrain.mesh = surface_tool.commit()
            collision_shape.shape = terrain.mesh.create_trimesh_shape()
        else:
            print("No vertices affected by destruction.")

func on_bullet_exploded(explosion_position:Vector3,explosion_radius:float):
    destroy_terrain(explosion_position,explosion_radius)