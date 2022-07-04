extends Node



enum State {
	NotSpawned,
	Active,
	StateMax, # not a valid state
}

signal state_changed(old, new)
signal movement_state_changed(old, new)
signal input_state_changed(to)

# Movement
signal jump_hold_started()
signal jump_hold_updated(new_time)
signal jump_hold_ended(time)
signal jumped()
signal respawn()
signal landed()
signal started_hypno()
signal started_tether()

var state: int = State.NotSpawned setget set_state
var is_player_on_ground := false setget set_is_player_on_ground, get_is_player_on_ground
var is_player_input_active := true setget set_is_player_input_active, get_is_player_input_active
var is_player_camera_active := true setget set_is_player_camera_active, get_is_player_camera_active
var is_player_using_hypno := false setget set_is_player_using_hypno, get_is_player_using_hypno
var is_player_tethered := false setget set_is_player_tethered, get_is_player_tethered
var load_position := false

onready var timer := Timer.new()


func _ready() -> void:
	add_child(timer)
	timer.wait_time = 30
	timer.connect("timeout", SaveManager, "save", [-1])
	timer.start()
	timer.paused = not is_player_input_active


func _notification(what: int) -> void:
	match what:
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
			if get_tree().current_scene and get_tree().current_scene.filename in ["res://areas/new_level_1/level_1.tscn", "res://areas/level_1/shortened.tscn"]:
				SaveManager.save(-1)
			get_tree().quit()
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			if get_tree().current_scene and get_tree().current_scene.filename in ["res://areas/new_level_1/level_1.tscn", "res://areas/level_1/shortened.tscn"]:
				SaveManager.save(-1)
			get_tree().quit()


func set_state(to: int) -> void:
	if to < 0 or to >= State.StateMax:
		push_error("Cannot set player state to invalid int %d" % to)
		return
	
	emit_signal("state_changed", state, to)
	state = to
	
	
func set_is_player_on_ground(value: bool) -> void:
	is_player_on_ground = value
	if value:
		emit_signal("landed")
	else:
		emit_signal("jumped")
	
	
func get_is_player_on_ground() -> bool:
	return is_player_on_ground


func set_is_player_input_active(value: bool) -> void:
	is_player_input_active = value
	timer.paused = not is_player_input_active
	emit_signal("input_state_changed", value)


func get_is_player_input_active() -> bool:
	return state > 0 and is_player_input_active
	
	
func set_is_player_camera_active(value: bool) -> void:
	is_player_camera_active = value
	
	
func get_is_player_camera_active() -> bool:
	return state > 0 and is_player_camera_active
	
	
func set_is_player_using_hypno(value: bool) -> void:
	is_player_using_hypno = value
	if value:
		emit_signal("started_hypno")
	
	
func get_is_player_using_hypno() -> bool:
	return is_player_using_hypno
	
	
func set_is_player_tethered(value: bool) -> void:
	is_player_tethered = value
	if value:
		emit_signal("started_tether")
	
	
func get_is_player_tethered() -> bool:
	return is_player_tethered


func _save() -> void:
	var save_data := SaveManager.get_save_dict("player_state")
	if get_tree().current_scene.filename != ProjectSettings.get("application/run/main_scene"):
		save_data["area"] = get_tree().current_scene.filename
