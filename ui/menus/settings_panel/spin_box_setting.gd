extends SpinBox


export var section: String
export var setting: String
var original_value: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_to_setting()


func set_to_setting() -> void:
	value = float(Settings.settings[section][setting])


func reset_setting() -> void:
	if Settings.settings[section][setting] != original_value:
		Settings.set_setting(section, setting, original_value)
		set_to_setting()


func _on_SpinBox_value_changed(value: float) -> void:
	Settings.set_setting(section, setting, int(value))


func record_current_values() -> void:
	original_value = Settings.settings[section][setting]
