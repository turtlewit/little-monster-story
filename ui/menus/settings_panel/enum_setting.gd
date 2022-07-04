extends OptionButton


export(Array, String) var choices
export var section: String
export var setting: String
var original_value: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for choice in choices:
		add_item(choice)
	set_to_setting()


func set_to_setting() -> void:
	selected = float(Settings.settings[section][setting])


func reset_setting() -> void:
	if Settings.settings[section][setting] != original_value:
		Settings.set_setting(section, setting, original_value)
		set_to_setting()


func record_current_values() -> void:
	original_value = Settings.settings[section][setting]


func _on_OptionButton_item_selected(index: int) -> void:
	Settings.set_setting(section, setting, index)
