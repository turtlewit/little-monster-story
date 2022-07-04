class_name ChoiceButton
extends TextureButton

signal button_pressed

export(AudioStream) var sound_hover: AudioStream
export(AudioStream) var sound_click: AudioStream

var auto_grab := false
var button_ready := false
var destroyed := false

onready var tween_invert := get_node("TweenInvert") as Tween
onready var shader := get_material() as ShaderMaterial

func _ready() -> void:
	#set_material(get_material().duplicate() as Material)
	set_modulate(Color(1, 1, 1, 0))
	if not auto_grab:
		tween_invert.interpolate_property(shader, "shader_param/invert_amount", 1.0, 0.0, 0.4)
	else:
		shader.set_shader_param("invert_amount", 1.0)
		
	tween_invert.interpolate_property(self, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.4)
	tween_invert.start()
	
	
func grab_focus_deferred() -> void:
	auto_grab = true
	

func set_choice_text(text: String) -> void:
	(get_node("Text") as Label).set_text(text)


func destroy() -> void:
	button_ready = false
	destroyed = true
	tween_invert.interpolate_property(shader, "shader_param/invert_amount", shader.get_shader_param("invert_amount"), 1.0, 0.4)
	tween_invert.interpolate_property(self, "modulate", get_modulate(), Color(1, 1, 1, 0), 0.4)
	tween_invert.start()


func _on_focus_grabbed() -> void:
	if button_ready:
		if not auto_grab:
			Controller.play_sound_oneshot(sound_hover, -4.0, rand_range(0.95, 1.05), "SFX")
			tween_invert.interpolate_property(shader, "shader_param/invert_amount", shader.get_shader_param("invert_amount"), 1.0, 0.4)
			tween_invert.start()
	else:
		release_focus()


func _on_focus_released() -> void:
	if button_ready:
		tween_invert.interpolate_property(shader, "shader_param/invert_amount", shader.get_shader_param("invert_amount"), 0.0, 0.4)
		tween_invert.start()


func _on_ChoiceButton_pressed() -> void:
	if button_ready:
		Controller.play_sound_oneshot(sound_click, 0.0, rand_range(0.98, 1.05), "SFX")
		emit_signal("button_pressed", get_position_in_parent())
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_TweenInvert_tween_all_completed() -> void:
	if not button_ready and not destroyed:
		button_ready = true
		if auto_grab:
			grab_focus()
			auto_grab = false
