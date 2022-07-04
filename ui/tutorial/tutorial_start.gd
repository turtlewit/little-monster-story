extends Node

signal moved_camera(index)
signal changed_direction(index)
signal jumped(index)


func _ready() -> void:
	PlayerState.connect("jumped", self, "jump")


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_forward") or Input.is_action_just_pressed("move_back") or Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		emit_signal("changed_direction", 1)
			
	if Input.is_action_just_pressed("camera_up") or Input.is_action_just_pressed("camera_down") or Input.is_action_just_pressed("camera_left") or Input.is_action_just_pressed("camera_right"):
		emit_signal("moved_camera", 0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		emit_signal("moved_camera", 0)
		

func jump() -> void:
	emit_signal("jumped", 2)
