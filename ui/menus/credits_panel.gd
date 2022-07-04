extends Panel

var old_focus: Control


func _ready() -> void:
	if visible:
		open()
	set_process_input(visible)


func open():
	old_focus = get_focus_owner()
	$ButtonBack.grab_focus()


func button(index: int) -> void:
	match index:
		2: # Back
			hide()
		3: # Third party
			$Credits.hide()
			$ButtonThirdParty.hide()
			$ButtonBack.hide()
			$Thirdparty.show()
			$ButtonThirdParty2.show()
			
		4: # Third party back
			$Thirdparty.hide()
			$ButtonThirdParty2.hide()
			$Credits.show()
			$ButtonThirdParty.show()
			$ButtonBack.show()


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_cancel"):
		hide()


func _on_CreditsPanel_visibility_changed() -> void:
	set_process_input(visible)
	if visible:
		open()
	else:
		$"../MouseBlock".hide()
		if old_focus:
			old_focus.grab_focus()
