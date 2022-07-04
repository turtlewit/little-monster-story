extends Node

signal used_grapple(index)


func _ready() -> void:
	PlayerState.connect("started_tether", self, "grapple")
	

func grapple() -> void:
	emit_signal("used_grapple", 0)
