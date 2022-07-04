extends CPUParticles


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerState.connect("movement_state_changed", self, "_on_player_movement_state_changed")
	set_process(false)


func _process(delta: float) -> void:
	var velocity: float = get_parent().get("linear_velocity").length()
	if velocity > 1:
		emitting = true
	else:
		emitting = false
	speed_scale = max(velocity * 0.5, 0.2)


func _on_player_movement_state_changed(old: int, new: int) -> void:
	if old == PlayerMovement.State.Sliding and new == PlayerMovement.State.PreJump:
		set_process(true)
	elif new == PlayerMovement.State.Sliding:
		set_process(true)
	else:
		emitting = false
		set_process(false)

