extends RigidBody3D

var initial_transform: Transform3D
@export
var rotation_speed: float = 1.0  # In radians per second

func _ready():
    initial_transform = global_transform

func _integrate_forces(state: PhysicsDirectBodyState3D):
    var current_basis = state.transform.basis
    var target_basis = initial_transform.basis
    
    # Calculate correct rotation difference (target * current^-1)
    var rotation_difference = target_basis.get_rotation_quaternion() * current_basis.get_rotation_quaternion().inverse()
    var axis = rotation_difference.get_axis()
    var angle = rotation_difference.get_angle()
    
    if angle > 0.01:
        # Calculate angular velocity correctly in rad/s
        var rotation_step = min(rotation_speed * state.step, angle)
        state.angular_velocity = axis * (rotation_step / state.step)
    else:
        state.angular_velocity = Vector3.ZERO
        state.transform.basis = target_basis  # Snap to target when close