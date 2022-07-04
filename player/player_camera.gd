extends ClippedCamera
class_name PlayerCamera


const H_SENSITIVITY: float = 1.5
const V_SENSITIVITY: float = 1.5
const H_MOUSE_SENSITIVITY: float = 0.3
const V_MOUSE_SENSITIVITY: float = 0.3

export var vertical_lerp_speed: float = 1
export var fast_vertical_lerp_mutliplier: float = 4
export var horizontal_lerp_speed: float = 1
export var player_vertical_velocity_fast_lerp_cutoff: float = 3.5

var h_sensitivity: float = 1
var h_mouse_sensitivity: float = 1
var v_sensitivity: float = 1
var v_mouse_sensitivity: float = 1

var rotation_offset: float = 0
var mouse_relative := Vector2()
var moving_platform: RigidBody
var moving_platform_offset := Vector3()
var fast_vertical_lerp := false

onready var pivot: Spatial = get_parent()
onready var player: Spatial = pivot.get_parent()
onready var initial_offset: Vector3 = pivot.translation
onready var initial_camera_offset: Vector3 = translation


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rotation_offset = pivot.global_transform.basis.get_euler().y
	player.call_deferred("remove_child", pivot)
	get_tree().current_scene.call_deferred("add_child", pivot)
	pivot.transform.origin = player.transform.origin + initial_offset
	PlayerState.connect("landed", self, "_on_player_landed", [false])
	PlayerState.connect("jumped", self, "_on_player_landed", [true])
	
	update_sensitivities(Settings.settings["controls"]["camera_sensitivity_mouse_x"], 
			Settings.settings["controls"]["camera_sensitivity_mouse_y"],
			Settings.settings["controls"]["camera_sensitivity_joystick_x"],
			Settings.settings["controls"]["camera_sensitivity_joystick_y"])
	
	Settings.connect("setting_modified", self, "_on_setting_modified")


func update_sensitivities(mouse_sensitivity_x, mouse_sensitivity_y, joystick_sensitivity_x, joystick_sensitivity_y) -> void:
	if joystick_sensitivity_x:
		h_sensitivity = H_SENSITIVITY * joystick_sensitivity_x
	if joystick_sensitivity_y:
		v_sensitivity = V_SENSITIVITY * joystick_sensitivity_y
	if mouse_sensitivity_x:
		h_mouse_sensitivity = H_MOUSE_SENSITIVITY * mouse_sensitivity_x
	if mouse_sensitivity_y:
		v_mouse_sensitivity = V_MOUSE_SENSITIVITY * mouse_sensitivity_y


func _on_setting_modified(section: String, setting: String, value) -> void:
	match section:
		"controls":
			match setting:
				"camera_sensitivity_mouse_x":
					update_sensitivities(value, null, null, null)
				"camera_sensitivity_mouse_y":
					update_sensitivities(null, value, null, null)
				"camera_sensitivity_joystick_x":
					update_sensitivities(null, null, value, null)
				"camera_sensitivity_joystick_y":
					update_sensitivities(null, null, null, value)


func _physics_process(delta: float) -> void:
	if not PlayerState.is_player_camera_active:
		return
		
	var horiz = Input.get_action_strength("camera_left") - Input.get_action_strength("camera_right")
	var vert = Input.get_action_strength("camera_up") - Input.get_action_strength("camera_down")
	rotation_offset += horiz * h_sensitivity * delta
	rotation_offset += -mouse_relative.x * h_mouse_sensitivity * delta
	pivot.rotate(Vector3.UP, horiz * h_sensitivity)
	pivot.rotation.y = rotation_offset
	pivot.rotation.x += vert * v_sensitivity * delta
	pivot.rotation.x += -mouse_relative.y * v_mouse_sensitivity * delta
	pivot.rotation.x = max(-1.4, min(.75, pivot.rotation.x))
	
	mouse_relative = Vector2()
	#pivot.global_transform.origin = player.transform.origin + initial_offset
	var target := player.transform.origin + initial_offset
	var target_h := Vector3(target.x, pivot.global_transform.origin.y, target.z)
	var target_v := Vector3(pivot.global_transform.origin.x, target.y, pivot.global_transform.origin.z)
	#var vdist := target.y - pivot.global_transform.origin.y
	var new_vpos: Vector3 
	if fast_vertical_lerp:
		new_vpos = lerp(pivot.global_transform.origin, target_v, vertical_lerp_speed * fast_vertical_lerp_mutliplier * delta) * Vector3(0, 1, 0)
	else:
		new_vpos = lerp(pivot.global_transform.origin, target_v, vertical_lerp_speed * delta) * Vector3(0, 1, 0)
	pivot.global_transform.origin = (lerp(pivot.global_transform.origin, target_h, horizontal_lerp_speed * delta) * Vector3(1, 0, 1)) + new_vpos
	if moving_platform:
		moving_platform_offset = moving_platform.global_transform.affine_inverse().xform(pivot.global_transform.origin)
	
	rotation = Quat(rotation).slerp(Quat(), 5.0 * delta).get_euler()
	translation = lerp(translation, initial_camera_offset, 5.0 * delta)


func _input(event: InputEvent) -> void:
	if not PlayerState.is_player_camera_active:
		return
		
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		mouse_relative += motion.relative
	
	if event.is_action_pressed("center_camera"):
		pivot.rotation.y = player.rotation.y


func _on_player_landed(jump: bool) -> void:
	if jump:
		if player.get("linear_velocity").y > player_vertical_velocity_fast_lerp_cutoff:
			fast_vertical_lerp = true
		else:
			fast_vertical_lerp = false
	else:
		var pmp = player.get("moving_platform")
		if pmp and pmp != moving_platform:
			if moving_platform:
				moving_platform.disconnect("moved", self, "_on_moving_platform_moved")
			moving_platform = pmp
			moving_platform.connect("moved", self, "_on_moving_platform_moved")
			moving_platform_offset = moving_platform.global_transform.affine_inverse().xform(pivot.global_transform.origin)
		elif not pmp and moving_platform:
			moving_platform.disconnect("moved", self, "_on_moving_platform_moved")
			set_deferred("moving_platform", null)


func _on_moving_platform_moved() -> void:
	if player.get("state") in [0, 1]:
		pivot.transform.origin = moving_platform.global_transform.xform(moving_platform_offset)
