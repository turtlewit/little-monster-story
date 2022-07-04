extends Control

class_name DialogueChoice

signal choice_selected(index)

const ChoiceButtonRef := preload("res://systems/dialogue/choice_button.tscn")

var buttons := Array()

func create(choices: Array) -> void:
	var previous_button: ChoiceButton = null
	for i in range(len(choices)):
		var button := ChoiceButtonRef.instance() as ChoiceButton
		
		var choice := choices[i] as String
		button.set_choice_text(choice)
		
		if i == 0 and not Input.get_connected_joypads().empty():
			button.grab_focus_deferred()
			
		button.connect("button_pressed", self, "choice_clicked")
		get_node("Choices").add_child(button)
		buttons.push_back(button)
		
		if previous_button != null:
			var prev := previous_button.get_path()
			var this := button.get_path()
			button.set_focus_previous(prev)
			button.set_focus_neighbour(MARGIN_LEFT, prev)
			previous_button.set_focus_next(this)
			previous_button.set_focus_neighbour(MARGIN_RIGHT, this)
			
		previous_button = button
		
	MouseModeStack.push_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func choice_clicked(index: int) -> void:
	emit_signal("choice_selected", index)
	MouseModeStack.pop_mouse_mode()

	for but in buttons:
		(but as ChoiceButton).destroy()
		
	(get_node("TimerDestroy") as Timer).start()
	
	
func _on_TimerDestroy_timeout() -> void:
	queue_free()
