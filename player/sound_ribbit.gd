extends AudioStreamPlayer3D


const particles := preload("res://player/ribbit_particles.tscn")

onready var animation_tree: AnimationTree = get_node("../AnimationTree")


func _ready() -> void:
	PlayerState.connect("input_state_changed", self,"_on_input_state_changed")


func _on_input_state_changed(enable: bool) -> void:
	set_process_input(enable)


func _input(event: InputEvent) -> void:
	if not playing and event.is_action_pressed("ribbit"):
		play()
		animation_tree["parameters/Ribbit/playback"].travel("Ribbit")
		add_child(particles.instance())
