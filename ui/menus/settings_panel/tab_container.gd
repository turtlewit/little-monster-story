extends TabContainer


func _ready() -> void:
	set_process_input(is_visible_in_tree())


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_tab_next"):
		current_tab = (current_tab + 1) % get_tab_count()
		get_current_tab_control().get_child(0).get_child(0).get_child(0).get_child(1).grab_focus()
	elif event.is_action_pressed("ui_tab_previous"):
		current_tab = fposmod((current_tab - 1), get_tab_count())
		get_current_tab_control().get_child(0).get_child(0).get_child(0).get_child(1).grab_focus()



func _on_TabContainer_visibility_changed() -> void:
	set_process_input(is_visible_in_tree())
