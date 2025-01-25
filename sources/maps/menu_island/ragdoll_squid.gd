class_name RagdollSquid
extends RigidBody3D

@onready
var body: MeshInstance3D = $Squid/Armature/Skeleton3D/Cylinder
@onready
var eyes: MeshInstance3D = $Squid/Cylinder_001
@onready
var squish_sound_effect: AudioStreamPlayer3D = $SquishAudio

var color: Color = Color(1.0,1.0,1.0,1.0)

func _physics_process(_delta: float) -> void:
	if(global_position.y < -10):
		queue_free()
        

func set_color(c: Color)->void:
	color = c
	body.get_surface_override_material(0).albedo_color = color
	eyes.get_surface_override_material(0).albedo_color = color


func _on_body_entered(body: Node) -> void:
	var normal_vector = (global_position - body.global_position).normalized()
	var basis = Basis.looking_at(normal_vector, Vector3.UP)  # Align -Z axis with normal
	var rotation_radians = basis.get_euler()
	var rotation_degrees = rotation_radians * (180.0 / PI)
	SplatterDecal.create_splatter(get_parent().get_parent(),global_transform.origin,color,rotation_degrees)
	if(squish_sound_effect.playing == false):
		squish_sound_effect.play()

