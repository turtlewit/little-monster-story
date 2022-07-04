extends Control

export(Texture) var interact_keyboard: Texture
export(Texture) var interact_controller: Texture


func _ready() -> void:
	Input.connect("joy_connection_changed", self, "set_interact_controls")
	
	if not Input.get_connected_joypads().empty():
		set_interact_controls(0, true)


func set_interact_controls(_device_id: int, controller: bool) -> void:
	if controller:
		($CenterContainer/InteractBox as TextureRect).set_texture(interact_controller)
	else:
		($CenterContainer/InteractBox as TextureRect).set_texture(interact_keyboard)


func show_interact_prompt(show: bool, text: String = ""):
	var tween := $TweenInteract as Tween
	tween.interpolate_property($CenterContainer/InteractBox as TextureRect, "self_modulate", Color(1, 1, 1, 0 if show else 1), Color(1, 1, 1, 1 if show else 0), 0.5)
	var label := $InteractText as Label
	tween.interpolate_property(label, "self_modulate", Color(1, 1, 1, 0 if show else 1), Color(1, 1, 1, 1 if show else 0), 0.5)
	if show:
		label.set_text(text)
		
	tween.start()
