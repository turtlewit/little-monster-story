extends RigidBody
class_name RotatingLog


signal moved()

export var angle: Vector3 = -Vector3.FORWARD
export var velocity: float = 1.0

var time: float = 0
var other_body: KinematicBody

onready var original_angle: Quat = transform.basis.get_rotation_quat()
onready var original_transform := transform


func _ready() -> void:
	angle = angle.normalized()
	if not is_in_group("MovingPlatform"):
		add_to_group("MovingPlatform")


func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	time += get_physics_process_delta_time()
	
	# We want set our rotation to our original angle, then rotate to the new rotation
	state.transform.basis = Basis(original_angle * Quat(angle, velocity * time))
	
	emit_signal("moved")


func set_move_body(body: KinematicBody) -> void:
	other_body = body
