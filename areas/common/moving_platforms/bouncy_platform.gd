extends RigidBody


signal moved()

export var springiness: float = 4.0
export var dampening: float = 0.05
export var constant_force: float = -1.0

var other_body: KinematicBody setget set_other_body
var vertical_velocity := 0.0
var vertical_offset := 0.0
func set_other_body(v: KinematicBody) -> void:
	other_body = v
	vertical_velocity = -2.0

onready var original_origin := global_transform.origin

func _ready() -> void:
	if not is_in_group("MovingPlatform"):
		add_to_group("MovingPlatform")

	mode = MODE_KINEMATIC
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true
	custom_integrator = true
	can_sleep = false


func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	var k = springiness
	var d = dampening
	var x = vertical_offset
	if other_body != null:
		x -= 0.25
	var F = (k * -x) + (d * -vertical_velocity)
	vertical_velocity += F;
	if other_body != null:
		vertical_velocity += constant_force
	vertical_offset += vertical_velocity * get_physics_process_delta_time()
	state.transform.origin = original_origin + Vector3(0, vertical_offset, 0)
	emit_signal("moved")
