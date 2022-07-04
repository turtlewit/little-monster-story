extends Node

signal walljumped()

func _ready() -> void:
	PlayerState.connect("landed", self, "walljump")


func walljump() -> void:
	emit_signal("walljumped", 0)
