extends Camera

const H_SENSITIVITY: float = 1.5
const V_SENSITIVITY: float = 1.5
const H_MOUSE_SENSITIVITY: float = 0.3
const V_MOUSE_SENSITIVITY: float = 0.3
const MOVEMENT_SPEED: float = 10.0

var mouse_input: Vector2
var yaw: float # y axis
var pitch: float # x axis


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	MouseModeStack.push_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _exit_tree() -> void:
	MouseModeStack.pop_mouse_mode()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var input := Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("fly_camera_up") - Input.get_action_strength("fly_camera_down"),
		Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	)
	
	var direction := input.normalized()
	var force := input.length()
	
	var speed := MOVEMENT_SPEED
	if Input.is_action_pressed("fly_camera_fast"):
		speed *= 2
	
	var forward := -transform.basis.z
	
	var right := transform.basis.x
	
	translation += ((right * direction.x) + (Vector3.UP * direction.y) + (forward * direction.z)) * force * speed * delta
	
	
	var look_input = Vector2(
		((Input.get_action_strength("camera_right") - Input.get_action_strength("camera_left")) * Settings.settings["controls"]["camera_sensitivity_joystick_x"] * H_SENSITIVITY) + (mouse_input.x * Settings.settings["controls"]["camera_sensitivity_mouse_x"] * H_MOUSE_SENSITIVITY),
		((Input.get_action_strength("camera_up") - Input.get_action_strength("camera_down")) * Settings.settings["controls"]["camera_sensitivity_joystick_y"] * V_SENSITIVITY) + (mouse_input.y * Settings.settings["controls"]["camera_sensitivity_mouse_y"] * V_MOUSE_SENSITIVITY)
	)
	
	yaw -= look_input.x * delta
	pitch -= look_input.y * delta
	
	pitch = clamp(pitch, -PI / 2, PI / 2)
	
	rotation = (Quat(Vector3.UP, yaw) * Quat(Vector3.RIGHT, pitch)).get_euler()
	
	mouse_input = Vector2()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		mouse_input += motion.relative
