extends Node


var gamepad_index: int = 0


func _ready() -> void:
	gamepad_index = Settings.settings["controls"]["gamepad_index"]
	set_input_event_devices()
	Settings.connect("setting_modified", self, "_on_setting_modified")


func _on_setting_modified(section: String, key: String, value) -> void:
	if section == "controls" and key == "gamepad_index":
		gamepad_index = value
		set_input_event_devices()


func set_input_event_devices() -> void:
	for action in InputMap.get_actions():
		for event in InputMap.get_action_list(action):
			if event is InputEventJoypadButton:
				var button := event as InputEventJoypadButton
				button.device = gamepad_index
			elif event is InputEventJoypadMotion:
				var motion := event as InputEventJoypadMotion
				motion.device = gamepad_index
