extends VBoxContainer


const template_script := """
extends Node

func write_to_file(filename: String, contents) -> void:
	Console.write_to_file(filename, contents)

func print_file_contents(filename: String) -> void:
	Console.print_file_contents(filename)

func fly() -> void:
	Console.fly()

func teleport() -> void:
	Console.teleport()

func run() -> void:
	{command}

"""

var old_player_input_state: bool
onready var line_edit: LineEdit = $LineEdit

var history := Array()
var history_position: int = 0
var current_command := ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func run_command(command: String) -> void:
	var script_text := template_script.format({"command": command})
	var script := GDScript.new()
	script.source_code = script_text
	script.reload()
	var node := Node.new()
	node.set_script(script)
	get_tree().root.add_child(node)
	node.call("run")
	node.queue_free()


func _on_LineEdit_text_entered(new_text: String) -> void:
	history.append(new_text)
	history_position = 0
	run_command(new_text)
	line_edit.text = ""


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_console"):
		visible = !visible
		if visible:
			old_player_input_state = PlayerState.is_player_input_active
			PlayerState.is_player_input_active = false
			line_edit.call_deferred("grab_focus")
		else:
			PlayerState.is_player_input_active = old_player_input_state
	elif event.is_action_pressed("ui_up"):
		move_in_history(-1)
	elif event.is_action_pressed("ui_down"):
		move_in_history(1)


func move_in_history(direction: int) -> void:
	match direction:
		-1:
			if history_position + direction < -len(history):
				return
		1:
			if history_position + direction > 0:
				return
	
	if history_position == 0:
		current_command = line_edit.text
	
	history_position += direction
	
	if history_position == 0:
		line_edit.text = current_command
	else:
		line_edit.text = history[len(history) + history_position]


# Console helpers
const FLYCAM := preload("res://systems/fly_camera/fly_camera.gd")
var flycam: Camera
var old_current: Camera


func write_to_file(filename: String, contents) -> void:
	var f := File.new()
	f.open(filename, File.WRITE)
	f.store_string(str(contents))
	f.close()


func print_file_contents(filename: String) -> void:
	var f := File.new()
	f.open(filename, File.READ)
	print(f.get_as_text())
	f.close()


func teleport() -> void:
	if not flycam:
		return
	
	var players := get_tree().get_nodes_in_group("Player")
	if len(players) == 0:
		return
	
	var player: Spatial = players[0]
	player.global_transform.origin = flycam.global_transform.origin


func fly() -> void:
	if flycam != null:
		old_player_input_state = true
		flycam.queue_free()
		flycam = null
		if old_current:
			old_current.current = true
	else:
		old_player_input_state = false
		flycam = Camera.new()
		flycam.set_script(FLYCAM)
		flycam.translation = get_viewport().get_camera().global_transform.origin
		old_current = get_viewport().get_camera()
		get_tree().root.add_child(flycam)
		flycam.current = true
