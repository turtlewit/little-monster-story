extends Node

signal used_hypno(index)


func _ready() -> void:
	PlayerState.connect("started_hypno", self, "hypno")
	

func hypno() -> void:
	emit_signal("used_hypno", 0)
