extends "res://ui/menus/settings_panel/spin_box_setting.gd"


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


func _ready() -> void:
	._ready()
	set_gamepad_name()


func set_gamepad_name() -> void:
	var n := Input.get_joy_name(value)
	if n.length() > 0:
		suffix = "(%s)" % Input.get_joy_name(value)
	else:
		suffix = "(No Joystick Found)"


func _on_SpinBox_value_changed(value: float) -> void:
	._on_SpinBox_value_changed(value)
	set_gamepad_name()
