extends RigidBody
class_name MovingPlatform


signal moved()

export var amplitude: float = 1
export var period: float = 1

onready var original_origin := global_transform.origin
var time: float = 0
var other_body: KinematicBody


func _ready() -> void:
	if not is_in_group("MovingPlatform"):
		add_to_group("MovingPlatform")


func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	time += get_physics_process_delta_time()
	var old_position := state.transform.origin
	var new_pos := original_origin + Vector3(0, 0, 1) * triangle_wave(time, amplitude, period)
	state.transform.origin = original_origin + Vector3(0, 0, 1) * triangle_wave(time, amplitude, period)
	
	emit_signal("moved")


func set_move_body(body: KinematicBody) -> void:
	other_body = body


func triangle_wave(x: float, a: float, p: float) -> float:
	return (2 * a / PI) * asin(sin(2*PI*x/p))
