extends HSlider


export var setting: String
var original_value: float


func _ready() -> void:
	set_to_setting()


func set_to_setting() -> void:
	value = Settings.settings["volume"][setting] * 100.0


func _on_HSlider_value_changed(value: float) -> void:
	Settings.set_setting("volume", setting, value / 100.0)


func record_current_values() -> void:
	original_value = Settings.settings["volume"][setting]


func reset_setting() -> void:
	if Settings.settings["volume"][setting] != original_value:
		Settings.set_setting("volume", setting, original_value)
		set_to_setting()
