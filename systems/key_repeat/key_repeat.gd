extends Node


const key_repeat_interval: float = 1.0 / 25.0
const key_repeat_delay: float = 0.6
const actions := [
	"ui_up",
	"ui_down",
	"ui_left",
	"ui_right",
]

var repeat_keys := Array()


class RepeatKey extends Object:
	var action: String
	var timer: float
	var repeating: bool
	var event_down: InputEventAction
	var event_up: InputEventAction
	
	
	func _init(action_: String) -> void:
		self.action = action_
		event_down = InputEventAction.new()
		event_down.action = action_
		event_down.pressed = true
		event_down.device = Gamepad.gamepad_index
		event_up = InputEventAction.new()
		event_up.action = action_
		event_up.pressed = false
		event_up.device = Gamepad.gamepad_index
	
	
	func _process(delta: float) -> void:
		timer += delta
		if repeating:
			if timer >= key_repeat_interval:
				timer -= key_repeat_interval
				# UI doesn't seem to register repeat down inputs,
				# so we have to release the button, then press it again
				Input.parse_input_event(event_up)
				Input.parse_input_event(event_down)
		else:
			if timer >= key_repeat_delay:
				timer = 0
				repeating = true


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS


func _process(delta: float) -> void:
	for key in repeat_keys:
		if not Input.is_action_pressed(key.action):
			repeat_keys.erase(key)
			key.free()
		else:
			key._process(delta)


func _input(event: InputEvent) -> void:
	# Ignore actions generated from our code
	if event is InputEventAction:
		return
	
	for action in actions:
		if event.is_action_pressed(action):
			for key in repeat_keys:
				if action == key.action:
					return
			repeat_keys.append(RepeatKey.new(action))
