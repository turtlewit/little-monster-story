extends Node


var stack := []
var disable_mouse_grab := false


func _ready() -> void:
	# HTML5 needs to set mouse_mode within an input callback.
	disable_mouse_grab = Settings.settings["controls"]["disable_mouse_grab"]
	if OS.get_name() != "HTML5" or disable_mouse_grab:
		set_process_input(false)
	Settings.connect("setting_modified", self, "_on_setting_modified")


func _on_setting_modified(section: String, setting: String, value) -> void:
	if section == "controls" and setting == "disable_mouse_grab":
		disable_mouse_grab = value
		if disable_mouse_grab:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			set_process_input(false)
		elif OS.get_name() == "HTML5":
			set_process_input(true)


func set_mouse_mode(mode: int) -> void:
	if not disable_mouse_grab:
		Input.set_mouse_mode(mode)


func push_mouse_mode(var mode: int) -> void:
	stack.append(mode)
	set_mouse_mode(mode)


func pop_mouse_mode() -> void:
	if len(stack) > 0:
		stack.pop_back()
	
	if len(stack) > 0:
		set_mouse_mode(stack.back())
	else:
		set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event: InputEvent) -> void:
	if stack.size() > 0 and Input.get_mouse_mode() != stack.back() and event is InputEventMouseButton:
		set_mouse_mode(stack.back())
