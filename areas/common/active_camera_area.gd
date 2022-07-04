extends Area
class_name ActiveCameraArea


var player_camera: PlayerCamera
var player: Spatial
var target_transform := Transform()
var increasing := false
var decreasing := false

var total_enters := 0

export var original_target_lerp_percent = 0.0
export var lerp_speed: float = 5.0

onready var tween := Tween.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")
	set_physics_process(false)
	
	Settings.connect("setting_modified", self, "_on_setting_modified")
	set_disabled(Settings.settings["gameplay"]["disable_active_camera"])
	
	tween.playback_process_mode = Tween.TWEEN_PROCESS_PHYSICS
	add_child(tween)


func _on_setting_modified(section: String, setting: String, value) -> void:
	if section == "gameplay" and setting == "disable_active_camera":
		set_disabled(value)


func set_disabled(to: bool) -> void:
	for child in get_children():
		if child is CollisionShape:
			child.disabled = to


func _physics_process(delta: float) -> void:
	var target := _position_camera(delta)
	target_transform.origin = lerp(target_transform.origin, target.origin, delta * lerp_speed)
	target_transform.basis = Basis(Quat(target_transform.basis.get_rotation_quat()).slerp(target.basis.get_rotation_quat(), delta * lerp_speed))


func _position_camera(delta: float) -> Transform:
	return Transform()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	
	total_enters += 1
	
	if total_enters > 1:
		return
	
	if not body is RigidBody:
		player_camera = body.get("camera_pivot").get_node("PlayerCamera")
	else:
		player_camera = body.player.get("camera_pivot").get_node("PlayerCamera")
	player = player_camera.get("player")
	target_transform = _position_camera(get_physics_process_delta_time())

	set_physics_process(true)
	
	if tween.is_connected("tween_all_completed", self, "_on_exit_tween_completed"):
		tween.disconnect("tween_all_completed", self, "_on_exit_tween_completed")
	
	tween.remove_all()
	
	tween.interpolate_property(self, "original_target_lerp_percent", original_target_lerp_percent, 1.0, 3.0 * (1.0 - original_target_lerp_percent), Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.start()
	
	decreasing = false
	increasing = true
	
	if not tween.is_connected("tween_all_completed", self, "_on_enter_tween_completed"):
		tween.connect("tween_all_completed", self, "_on_enter_tween_completed")
	
	if not self in ActiveCameraAreaController.current_areas:
		ActiveCameraAreaController.add_area(self)


func _on_enter_tween_completed() -> void:
	increasing = false


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	
	total_enters -= 1
	
	if total_enters > 0:
		return
	
	
	if tween.is_connected("tween_all_completed", self, "_on_enter_tween_completed"):
		tween.disconnect("tween_all_completed", self, "_on_enter_tween_completed")
	
	decreasing = true
	increasing = false
	
	tween.remove_all()
	tween.interpolate_property(self, "original_target_lerp_percent", original_target_lerp_percent, 0.0, 3.0 * original_target_lerp_percent, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.start()
	
	if not tween.is_connected("tween_all_completed", self, "_on_exit_tween_completed"):
		tween.connect("tween_all_completed", self, "_on_exit_tween_completed")


func _on_exit_tween_completed() -> void:
	decreasing = false
	set_physics_process(false)
	if self in ActiveCameraAreaController.current_areas:
		ActiveCameraAreaController.remove_area(self)
