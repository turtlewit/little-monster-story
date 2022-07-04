extends Panel

export(bool) var main_menu := false

var old_focus: Control

func _ready() -> void:
	set_process_input(false)

func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_cancel"):
		visible = false


func _on_SettingsPanel_visibility_changed() -> void:
	if visible:
		set_process_input(true)
		propagate_call("record_current_values")
		old_focus = get_focus_owner()
		$"VBoxContainer/TabContainer/Volume/Panel/VBoxContainer/Master volume/HSlider".grab_focus()
	else:
		set_process_input(false)
		if main_menu:
			$"../MouseBlock".hide()
		if old_focus:
			old_focus.grab_focus()


func _on_SaveButton_pressed() -> void:
	visible = false
	var mouse_block = get_node("../MouseBlock")
	if mouse_block:
		mouse_block.visible = false
	Settings.save_settings()


func _on_CancelButton_pressed() -> void:
	propagate_call("reset_setting")
	visible = false
