extends Node
class_name CountUpTimer

var time: float = INF


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	time += delta


func start() -> void:
	time = 0
	set_process(true)


func continue() -> void:
	set_process(true)


func stop() -> float:
	set_process(false)
	return time
