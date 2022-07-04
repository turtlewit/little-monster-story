extends CheckBox


export var section: String
export var setting: String
var original_value: bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_to_setting()


func set_to_setting() -> void:
	pressed = Settings.settings[section][setting]


func _on_CheckBox_toggled(button_pressed: bool) -> void:
	Settings.set_setting(section, setting, button_pressed)


func reset_setting() -> void:
	if Settings.settings[section][setting] != original_value:
		Settings.set_setting(section, setting, original_value)
		set_to_setting()


func record_current_values() -> void:
	original_value = Settings.settings[section][setting]
