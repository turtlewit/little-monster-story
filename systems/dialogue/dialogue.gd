class_name Dialogue
extends Control

signal text_closed
signal choice_selected

export(AudioStream) var text_sound: AudioStream

const DialogueChoiceRef := preload("res://systems/dialogue/dialogue_choice.tscn")
const BbCodeRegexPat := "\\[.+?\\]"

var bbcode_regex := RegEx.new()

var sound_pitch := 1.0

var choices := Array()
var choice_mode := false
var choice_open := false

var allow_advance := false
var text_active := false
var finished := false
var closed := true

var text_length := -1

onready var text := get_node("CenterContainer/Box/Text") as RichTextLabel
onready var timer_text := get_node("TimerText") as Timer


func _ready() -> void:
	get_node("CenterContainer").hide()
	bbcode_regex.compile(BbCodeRegexPat)
	

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and not choice_open:
		if allow_advance:
			allow_advance = false
			($CenterContainer/Box/Advance2 as Sprite).hide()
			finished = true
			emit_signal("text_closed")
		elif text_active:
			timer_text.stop()
			text.set_visible_characters(len(text.get_bbcode()))
			text_active = false
			
			if choice_mode:
				show_choices()
			else:
				allow_advance = true
				($CenterContainer/Box/Advance2 as Sprite).show()


func display_text(text_: String, is_choice: bool, choices_: Array = []) -> void:
	text.set_bbcode(text_)
	text.set_visible_characters(0)
	text_length = len(strip_bbocde(text_))
	get_node("CenterContainer").show()
	
	if is_choice:
		choices = choices_
	elif not choices.empty():
		choices.clear()
		
	choice_mode = is_choice
	finished = false
	if closed:
		fade_animation(false)
	else:
		_on_TweenAlpha_tween_all_completed()


func set_speaker(speaker: String) -> void:
	var box := get_node("CenterContainer/Box/Namebox") as Control
	(box.get_node("Text") as Label).set_text(speaker)
	box.show()


func hide_speaker():
	get_node("CenterContainer/Box/Namebox").hide()


func fade_animation(out: bool) -> void:
	if not out:
		closed = false
	else:
		if closed:
			return
		else:
			closed = true
			
	var tween := get_node("TweenAlpha") as Tween
	tween.interpolate_property(get_node("CenterContainer/Box") as Control, "modulate", Color(1, 1, 1, 1 if out else 0), Color(1, 1, 1, 0 if out else 1), 0.1)
	tween.start()


func show_choices() -> void:
	var inst := DialogueChoiceRef.instance() as DialogueChoice
	get_tree().get_root().add_child(inst)
	inst.connect("choice_selected", self, "choice_clicked")
	inst.create(choices)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	choice_open = true
	
	
func set_sound_pitch(value: float) -> void:
	sound_pitch = value
	
	
func choice_clicked(index: int) -> void:
	emit_signal("choice_selected", index)
	($TimerSelectBuffer as Timer).start()
	
	
func strip_bbocde(string: String) -> String:
	return bbcode_regex.sub(string, "", true)
	
	
func _on_TweenAlpha_tween_all_completed() -> void:
	if not finished:
		text_active = true
		timer_text.start()
		
		
func _on_TimerText_timeout() -> void:
	Controller.play_sound_oneshot(text_sound, -6, sound_pitch, "Text")
	var chars := text.get_visible_characters()
	chars += 1
	text.set_visible_characters(chars)
	if chars >= text_length:
		timer_text.stop()
		text_active = false
		
		if choice_mode:
			show_choices()
		else:
			allow_advance = true
			($CenterContainer/Box/Advance2 as Sprite).show()


func _on_TimerSelectBuffer_timeout() -> void:
	choice_open = false
