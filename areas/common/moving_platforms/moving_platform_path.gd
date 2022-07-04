extends RigidBody
class_name MovingPlatformPath


signal moved()

const STATE_MOVING: int = 0
const STATE_PAUSED: int = 1
const STATE_ROTATING: int = 2

const ROTATION_DISABLED: int = 0
const ROTATION_NODE: int = 1
const ROTATION_CONTINUOUS: int = 2

export(bool) var interpolate_path: bool = false
export(int, "Disabled", "At Every Node", "Continuous") var rotation_mode: int = 0
export var speed: float = 1.0
export var pause_time: float = 0.0
export(Array, int) var pause_at_nodes := Array()
export(int, "Moving", "Paused") var state: int = STATE_MOVING
export var cycle_path := false
export var current_node: int = 0
export var springy: bool = true
export var springiness: float = 4.0
export var dampening: float = 0.05
export var constant_force: float = -1.0

var curve: Curve3D
var timer: Timer
var tween: Tween
var direction: int = 1
var vertical_velocity := 0.0
var vertical_offset := 0.0

var current_position := Vector3()
export var current_rotation := Quat()
var original_rotation := Quat()
var target_rotation := Quat()

var other_body: KinematicBody setget set_other_body
func set_other_body(v: KinematicBody) -> void:
	other_body = v
	vertical_velocity = -2.0

onready var original_path_transform: Transform


func _ready() -> void:
	for child in get_children():
		if child is Path:
			curve = child.curve
			original_path_transform = child.global_transform
			child.queue_free()
			break

	if not curve or curve.get_point_count() == 0:
		push_error("MovingPlatformPath ({0}) doesn't have a path child! Self-destructing...".format([get_path()]))
		set_script(null)
		return
	
	if not is_in_group("MovingPlatform"):
		add_to_group("MovingPlatform")

	mode = MODE_KINEMATIC
	axis_lock_linear_x = true
	axis_lock_linear_y = true
	axis_lock_linear_z = true
	axis_lock_angular_x = true
	axis_lock_angular_y = true
	axis_lock_angular_z = true

	timer = Timer.new()
	add_child(timer)
	timer.one_shot = true
	timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
	if pause_time > 0:
		timer.wait_time = pause_time
	timer.connect("timeout", self, "_on_timer_timeout")
	if state == STATE_PAUSED and current_node in pause_at_nodes:
		timer.start()

	tween = Tween.new()
	add_child(tween)
	tween.playback_process_mode = Tween.TWEEN_PROCESS_PHYSICS
	tween.connect("tween_all_completed", self, "_on_tween_completed")
	
	transform.origin = get_point_position(current_node)
	current_position = transform.origin
	current_rotation = transform.basis.get_rotation_quat()
	next_node()
	if state != STATE_PAUSED:
		start_tweens()


func _integrate_forces(state_: PhysicsDirectBodyState) -> void:
	if springy:
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
	match self.state:
		STATE_MOVING:
			state_.transform.origin = current_position + Vector3(0, vertical_offset, 0)
			if rotation_mode == ROTATION_CONTINUOUS:
				state_.transform.basis = Basis(current_rotation)
			emit_signal("moved")
		STATE_ROTATING:
			state_.transform.basis = Basis(current_rotation)
			emit_signal("moved")
	


func _on_timer_timeout() -> void:
	state = STATE_MOVING
	start_tweens()


func _on_tween_completed() -> void:
	match state:
		STATE_MOVING:
			next_node()
			if rotation_mode != ROTATION_NODE and pause_time > 0 and get_previous_node() in pause_at_nodes:
				state = STATE_PAUSED
				timer.start()
			elif rotation_mode == ROTATION_NODE:
				state = STATE_ROTATING
				start_tweens()
				return
			else:
				start_tweens()
		STATE_ROTATING:
			if pause_time > 0 and get_previous_node() in pause_at_nodes:
				state = STATE_PAUSED
				timer.start()
			else:
				state = STATE_MOVING
				start_tweens()


func get_point_position(idx: int) -> Vector3:
	return original_path_transform.xform(curve.get_point_position(idx))


func next_node() -> void:
	if not cycle_path:
		if current_node + direction == curve.get_point_count() or current_node + direction < 0:
			direction *= -1
		current_node = current_node + direction
	else:
		if current_node + 1 == curve.get_point_count():
			current_node = 1
		else:
			current_node += 1


func get_previous_node() -> int:
	if not cycle_path:
		if current_node - direction < 0 or current_node - direction == curve.get_point_count():
			return current_node + direction
		return current_node - direction
	if current_node < 1:
		return curve.get_point_count() - 1
	return current_node - 1


func looking_at(position: Vector3) -> Quat:
	var direction_ := -(position - translation).normalized()
	var right := transform.basis.y.normalized().cross(direction_).normalized()
	var r := Basis(right, transform.basis.y.normalized(), direction_).orthonormalized().get_rotation_quat()
	return r


func get_percent(idx: int) -> float:
	var offset := curve.get_closest_offset(curve.get_point_position(idx))
	if (idx == curve.get_point_count() - 1):
		return 1.0
	return offset / curve.get_baked_length()


func start_tweens() -> void:
	if speed == 0:
		return
	var target_position := get_point_position(current_node)
	target_rotation = looking_at(target_position)
	
	var duration := target_position.distance_to(current_position) / speed
	if interpolate_path and not state == STATE_ROTATING:
		tween.interpolate_method(self, "interpolate_position", get_percent(get_previous_node()), get_percent(current_node), duration)
	else:
		if state == STATE_MOVING:
			tween.interpolate_property(self, "current_position", current_position, target_position, duration)

	if rotation_mode == ROTATION_CONTINUOUS or state == STATE_ROTATING:
		original_rotation = transform.basis.get_rotation_quat()
		tween.interpolate_method(self, "interpolate_rotation", 0.0, 1.0, duration)
	
	tween.start()


func interpolate_position(percent: float) -> void:
	current_position = original_path_transform.xform(curve.interpolate_baked(percent * float(curve.get_baked_length())))


func interpolate_rotation(percent: float) -> void:
	current_rotation = original_rotation.slerp(target_rotation, percent)
