extends HSlider


export var section: String
export var setting: String
var original_value: float


func _ready() -> void:
	set_to_setting()


func set_to_setting() -> void:
	value = Settings.settings[section][setting]


func _on_HSlider_value_changed(value: float) -> void:
	Settings.set_setting(section, setting, value)


func record_current_values() -> void:
	original_value = Settings.settings[section][setting]


func reset_setting() -> void:
	if Settings.settings[section][setting] != original_value:
		Settings.set_setting(section, setting, original_value)
		set_to_setting()
