extends Area

class_name Tutorial

signal action_performed()
signal tutorial_finished()

export(Array, Texture) var keyboard_images := []
export(Array, Texture) var controller_images := []
export(Array, String) var action_signals := []
export(bool) var enable := true

const FADE_DELAY := 3.0

var started := false
var current_image := 0
var input_enabled := false

func _ready() -> void:
	for i in range(len(action_signals)):
		$Inputs.connect(action_signals[i], self, "action_performed", [], CONNECT_REFERENCE_COUNTED)

func action_performed(index: int) -> void:
	if input_enabled and index == current_image:
		input_enabled = false
		#($Sound as AudioStreamPlayer).play()
		current_image += 1
		var tween := $Tween as Tween
		var img := $CanvasLayer/Image as TextureRect
		tween.interpolate_property(img, "modulate", img.get_modulate(), Color(1, 1, 1, 0), 1.5)
		tween.start()
		emit_signal("action_performed")
		yield(tween, "tween_all_completed")
		if current_image < len(keyboard_images):
			show_next_image()
		else:
			finish_tutorial()
			
			
func destroy() -> void:
	if started:
		queue_free()


func _on_Tutorial_body_entered(body: Node) -> void:
	if enable and not started:
		started = true
		show_next_image()


func show_next_image() -> void:
	var tween := $Tween as Tween
	var img := $CanvasLayer/Image as TextureRect
	img.set_texture(controller_images[current_image] if len(Input.get_connected_joypads()) > 0 else keyboard_images[current_image])
	tween.interpolate_property(img, "modulate", img.get_modulate(), Color(1, 1, 1, 1), 1.5)
	tween.connect("tween_all_completed", self, "set_input_enabled", [true], CONNECT_ONESHOT)
	tween.start()
	
	
func start_tutorial() -> void:
	show_next_image()


func finish_tutorial() -> void:
	emit_signal("tutorial_finished")
	queue_free()
	
	
func set_input_enabled(value: bool) -> void:
	input_enabled = value


func _on_TimerSwapTexture_timeout() -> void:
	($CanvasLayer/Image as TextureRect).set_texture(controller_images[current_image] if len(Input.get_connected_joypads()) > 0 else keyboard_images[current_image])
