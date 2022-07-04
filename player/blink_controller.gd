extends Node


const minimum_time: float = 5.0
const maximum_time: float = 20.0

var current_time := 0.0
var target_time := 0.0

onready var tree: AnimationTree = get_parent()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize_time()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	current_time += delta
	
	if current_time >= target_time:
		randomize_time()
		tree["parameters/Blink/playback"].travel("Blink")


func randomize_time() -> void:
	target_time = minimum_time + (randf() * (maximum_time - minimum_time))
	current_time = 0.0
