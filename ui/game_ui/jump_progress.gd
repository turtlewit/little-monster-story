extends TextureProgress

onready var sound_charge := get_node("../SoundCharge") as AudioStreamPlayer


func _ready() -> void:
	PlayerState.connect("jump_hold_started", self, "_on_jump_start")
	PlayerState.connect("jump_hold_updated", self, "_on_jump_update")
	PlayerState.connect("jump_hold_ended", self, "_on_jump_finish")
	hide()


func _on_jump_start() -> void:
	show()
	value = 0


func _on_jump_update(time: float) -> void:
	var p := time / 0.8
	value = p * 100.0
	if p < 0.5:
		tint_progress = Color.green.linear_interpolate(Color.yellow, p * 2)
	else:
		tint_progress = Color.yellow.linear_interpolate(Color.red, (p - 0.5) * 2)


func _on_jump_finish(_t: float) -> void:
	hide()
