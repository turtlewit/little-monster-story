class_name Cutscene
extends Node

signal cutscene_finished

enum Command {
	Null,
	Start,
	End,

	DialogueText,
	DialogueTextChoice,
	
	CharacterAnimation,
	CharacterMove,
	CharacterTurn,
	
	Fade,
	CameraFade,
	CameraMove,
	CameraMoveToCamera,
	CameraMemorizePosition,
	CameraMoveToMemorized,
	LockCamera,
	
	PlaySound,
	PlayMusic,
	FadeMusic,
	
	DeclareRef,
	PlayEventAnimation,
	SetFlag,
	SetProperty,
	CallFunction,
	Wait,
}

const CommandMap: Dictionary = {
	"NULL": Command.Null,
	"START": Command.Start,
	"END": Command.End,
	
	"DIALOGUE": Command.DialogueText,
	"DIALOGUE_CHOICE": Command.DialogueTextChoice,
	
	"CHARACTER_ANIMATION": Command.CharacterAnimation,
	"CHARACTER_MOVE": Command.CharacterMove,
	"CHARACTER_TURN": Command.CharacterTurn,
	
	"FADE": Command.Fade,
	"CAMERA_FADE": Command.CameraFade,
	"CAMERA_MOVE": Command.CameraMove,
	"CAMERA_MOVE_TO_CAMERA": Command.CameraMoveToCamera,
	"CAMERA_MEMORIZE_POSITION": Command.CameraMemorizePosition,
	"CAMERA_MOVE_TO_MEMORIZED": Command.CameraMoveToMemorized,
	"LOCK_CAMERA": Command.LockCamera,
	
	"PLAY_SOUND": Command.PlaySound,
	"PLAY_MUSIC": Command.PlayMusic,
	"FADE_MUSIC": Command.FadeMusic,
	
	"DECLARE_REF": Command.DeclareRef,
	"PLAY_EVENT_ANIMATION": Command.PlayEventAnimation,
	"SET_FLAG": Command.SetFlag,
	"SET_PROPERTY": Command.SetProperty,
	# CALL_FUNCTION: Command.CallFunction,
	"WAIT": Command.Wait,
}

const CommandRegexPat := "^(\\w+)\\s+(.*)\\(([\\d\\-]+),\\s*([\\d\\-]+)\\)\\s+(.+)\\s+(\\{.*\\})$"
const DialogueRegexPat := "^\\[(.+),\\s*([\\d\\.\\-]+)\\]\\s*(.+)$"
const ChoiceRegexPat := "^\\[(.+),\\s*([\\d\\.\\-]+)\\]\\s*(.+)\\s*(\\[.*\\])$"
const FunctionRegexPat = "^(.+)\\s+(.+)\\s+(\\[.*\\])$"
const ShortWaitTime := 0.02

export(String, FILE, "*.yaml") var cutscene_file := String() setget set_cutscene_file
export(Dictionary) var sounds_and_music := Dictionary()
export(bool) var autostart := false

var command_regex := RegEx.new()
var dialogue_regex := RegEx.new()
var choice_regex := RegEx.new()
var function_regex := RegEx.new()

var cutscene_table := Dictionary()
var next_step := String()
var declared_refs := Dictionary()

var cutscene_running := false

var memorized_camera_pos := Transform()

const dialogue_ref := preload("res://systems/dialogue/dialogue.tscn")
var dialogue: Dialogue = null
const camera_crossfade_ref := preload("res://systems/cutscene/camera_crossfade.tscn")

onready var timer_wait := $TimerWait as Timer


func _ready() -> void:
	dialogue = dialogue_ref.instance() as Dialogue
	get_tree().get_root().call_deferred("add_child", dialogue)
	
	command_regex.compile(CommandRegexPat)
	dialogue_regex.compile(DialogueRegexPat)
	choice_regex.compile(ChoiceRegexPat)
	function_regex.compile(FunctionRegexPat)
	
	if autostart:
		start_cutscene()
		
		
func _process(_delta: float) -> void:
	if cutscene_running and Input.is_action_just_pressed("skip_cutscene"):
		skip_cutscene()
		
		
func start_cutscene(remove_camera_control: bool = false) -> void:
	PlayerState.is_player_input_active = false
	if remove_camera_control:
		PlayerState.is_player_camera_active = false
		(get_tree().get_current_scene().get_node("CameraPivot/PlayerCamera") as ClippedCamera).set_clip_to_bodies(false)
		
	generate_cutscene_table(cutscene_file)
	next_step = "NodeStart"
	cutscene_running = true
	run_cutscene_step()
	
	
func skip_cutscene() -> void:
	while cutscene_running:
		run_cutscene_step(true)


func generate_cutscene_table(cutscene_file_: String) -> void:
	var file := File.new()
	file.open(cutscene_file_, File.READ)
	cutscene_table = YAML.decode(file.get_as_text())
	file.close()


func run_cutscene_step(skipping: bool = false) -> void:
	var current_step := cutscene_table[next_step] as Dictionary
	var step_outputs := current_step["outputs"] as Dictionary
	var step_type := current_step["type"] as String
	var type_int := CommandMap[step_type] as int
	if type_int != Command.DialogueTextChoice and type_int != Command.End:
		var next_name := step_outputs[0] as String
		next_step = next_name

	var args := current_step["arguments"] as Dictionary
	var close_dialogue := true
	
	match type_int:
		Command.DialogueText:
			if not skipping:
				var speaker := args["speaker_name"] as String
				var pitch := args["sound_pitch"] as float
				var text := args["text"] as String
				dialogue.connect("text_closed", self, "run_cutscene_step", [], CONNECT_ONESHOT | CONNECT_REFERENCE_COUNTED)
				if speaker == "#":
					dialogue.hide_speaker()
				else:
					dialogue.set_speaker(speaker)
				
				dialogue.set_sound_pitch(pitch)
				dialogue.display_text(text, false)
				close_dialogue = false
			else:
				generic_wait(ShortWaitTime)
			
		Command.DialogueTextChoice:
			if not skipping:
				var speaker := args["speaker_name"] as String
				var pitch := args["sound_pitch"] as float
				var text := args["text"] as String
				var choices := args["choices"] as Array
				dialogue.connect("choice_selected", self, "run_cutscene_step_choice", [], CONNECT_ONESHOT | CONNECT_REFERENCE_COUNTED)
				if speaker == "#":
					dialogue.hide_speaker()
				else:
					dialogue.set_speaker(speaker)
					
				dialogue.set_sound_pitch(pitch)
				dialogue.display_text(text, true, choices)
				close_dialogue = false
			else:
				generic_wait(ShortWaitTime)
			
		Command.CharacterAnimation:
			if not skipping:
				var identifier := args["target_reference"] as String
				var animation := args["animation_name"] as String
				var tree := (declared_refs[identifier] as Node).get_node("AnimationTree") as AnimationTree
				var playback := tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
				playback.travel(animation)
			generic_wait(ShortWaitTime)

		Command.CharacterMove:
			var identifier := args["target_reference"] as String
			var position := args["target_location"] as Dictionary
			var x := position["x"] as float
			var y := position["y"] as float
			var z := position["z"] as float
			var time := 0.0 if skipping else (args["time"] as float)
			var target := declared_refs[identifier] as Spatial
			
			var tween_move := Controller.construct_tween()
			tween_move.interpolate_property(target, "translation", target.get_translation(), Vector3(x, y, z), time)
			tween_move.start()
			generic_wait(ShortWaitTime)
			
		Command.CharacterTurn:
			var identifier := args["target_reference"] as String
			var rotation := args["target_rotation"] as Dictionary
			var x := rotation["x"] as float
			var z := rotation["z"] as float
			var time := 0.0 if skipping else (args["time"] as float)
			var target := declared_refs[identifier] as Spatial
			var target_direction := Vector3(x, target.get_translation().y, z)
			
			var start_rot := target.get_rotation()
			target.look_at(target_direction, Vector3.UP)
			var lookat := target.get_rotation()
			target.set_rotation(start_rot)
			
			var tween_turn := Controller.construct_tween()
			tween_turn.interpolate_property(target, "rotation", start_rot, lookat, time)
			tween_turn.start()
			generic_wait(ShortWaitTime)
			
		Command.Fade:
			if not skipping:
				var time := args["time"] as float
				var color := args["color"] as String
				var fadein := args["fadein"] as bool
				Controller.fade(time, fadein, Color(color))
			generic_wait(ShortWaitTime)
		
		Command.CameraFade:
			var from := args["from_reference"] as String
			var to := args["to_reference"] as String
			var time := 0.0 if skipping else (args["time"] as float)
			var cam_1 := declared_refs[from] as Camera
			var cam_2 := declared_refs[to] as Camera
			
			if time == 0.0:
				cam_1.set_current(false)
				cam_2.set_current(true)
			else:
				var crossfade := camera_crossfade_ref.instance() as CameraCrossfade
				cam_2.get_parent().add_child(crossfade)
				crossfade.crossfade(cam_1, cam_2, time)
				
			generic_wait(ShortWaitTime)
			
		Command.CameraMove:
			var identifier := args["target_reference"] as String
			var position := args["position"] as Dictionary
			var rotation := args["rotation"] as Dictionary
			var pos_x := position["x"] as float
			var pos_y := position["y"] as float
			var pos_z := position["z"] as float
			var rot_x := rotation["x"] as float
			var rot_y := rotation["y"] as float
			var rot_z := rotation["z"] as float
			var time := 0.0 if skipping else (args["time"] as float)
			var interp := args["interpolation"] as bool
			var camera := declared_refs[identifier] as Camera
			
			var xform := Transform()
			xform = xform.translated(Vector3(pos_x, pos_y, pos_z))
			xform.basis = xform.basis.rotated(Vector3(1, 0, 0), deg2rad(rot_x))
			xform.basis = xform.basis.rotated(Vector3(0, 1, 0), deg2rad(rot_y))
			xform.basis = xform.basis.rotated(Vector3(0, 0, 1), deg2rad(rot_z))
			xform = xform.orthonormalized()
			
			var tween_camera := Controller.construct_tween()
			tween_camera.interpolate_property(camera, "global_transform", camera.get_global_transform(), xform, time, Tween.TRANS_QUINT if interp else Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween_camera.start()
			generic_wait(ShortWaitTime)
			
		Command.CameraMoveToCamera:
			var identifier := args["target_reference"] as String
			var target := args["camera_target"] as String
			var camera := declared_refs[identifier] as Camera
			var camera_target := declared_refs[target] as Camera
			var time := 0.0 if skipping else (args["time"] as float)
			var interp := args["interpolation"] as bool
			
			var xform := camera_target.get_global_transform()
			
			var tween_camera := Controller.construct_tween()
			tween_camera.interpolate_property(camera, "global_transform", camera.get_global_transform(), xform, time, Tween.TRANS_QUINT if interp else Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween_camera.start()
			generic_wait(ShortWaitTime)
			
		Command.CameraMemorizePosition:
			var identifier := args["target_reference"] as String
			
			memorized_camera_pos = (declared_refs[identifier] as Camera).get_global_transform()
			generic_wait(ShortWaitTime)
			
		Command.CameraMoveToMemorized:
			var identifier := args["target_reference"] as String
			var time := 0.0 if skipping else (args["time"] as float)
			var interp := args["interpolation"] as bool
			var camera := declared_refs[identifier] as Camera
			
			var tween_camera := Controller.construct_tween()
			tween_camera.interpolate_property(camera, "global_transform", camera.get_global_transform(), memorized_camera_pos, time, Tween.TRANS_QUINT if interp else Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			tween_camera.start()
			generic_wait(ShortWaitTime)
			
		Command.LockCamera:
			PlayerState.is_player_camera_active = false
			(get_tree().get_current_scene().get_node("CameraPivot/PlayerCamera") as ClippedCamera).set_clip_to_bodies(false)
			generic_wait(ShortWaitTime)
			
		Command.PlaySound:
			if not skipping:
				var sound := args["sound_name"] as String
				var volume := args["volume"] as float
				var pitch := args["pitch"] as float
				Controller.play_sound_oneshot(sounds_and_music[sound] as AudioStream, volume, pitch)
			generic_wait(ShortWaitTime)
			
		Command.PlayMusic:
			var music := args["sound_name"] as String
			var volume := args["volume"] as float
			var pitch := args["pitch"] as float
			Controller.play_musict(sounds_and_music[music] as AudioStream, volume, pitch)
			generic_wait(ShortWaitTime)
			
		Command.FadeMusic:
			var time := 0.0 if skipping else (args["time"] as float)
			var fadein := args["fadein"] as bool
			Controller.fade_music(time, fadein)
			generic_wait(ShortWaitTime)
			
		Command.DeclareRef:
			var identifier := args["reference_name"] as String
			var path := args["target"] as String
			declared_refs[identifier] = get_tree().get_current_scene().get_node(path)
			generic_wait(ShortWaitTime)
			
		Command.PlayEventAnimation:
			if not skipping:
				var name_ := args["animation_name"] as String
				(get_node("AnimationPlayer") as AnimationPlayer).play(name_)
			generic_wait(ShortWaitTime)
			
		Command.SetFlag:
			var name_ := args["flag"] as String
			var value := args["value"] as int
			Controller.set_flag(name_, value)
			
		Command.SetProperty:
			var identifier := args["target_reference"] as String
			var property := args["property"] as String
			var value = args["value"]
			(declared_refs[identifier] as Node).set(property, value)
			generic_wait(ShortWaitTime)
			
		Command.Wait:
			if not skipping:
				var time := args["time"] as float
				generic_wait(time)
			else:
				generic_wait(ShortWaitTime)
			
		Command.Start:
			generic_wait(ShortWaitTime)
			
		Command.End:
			cutscene_running = false
			PlayerState.is_player_camera_active = true
			PlayerState.is_player_input_active = true
			(get_tree().get_current_scene().get_node("CameraPivot/PlayerCamera") as ClippedCamera).set_clip_to_bodies(true)
			emit_signal("cutscene_finished")
			queue_free()
			
		_:
			push_error("Parsed an invalid cutscene command (%s)" % current_step["type"])

	if close_dialogue:
		dialogue.fade_animation(true)
		
		
func run_cutscene_step_choice(choice_index: int) -> void:
	var current_step := cutscene_table[next_step] as Dictionary
	var step_outputs := current_step["outputs"] as Dictionary
	var next_name := step_outputs[choice_index] as String
	
	next_step = next_name
	run_cutscene_step()


func generic_wait(time: float) -> void:
	timer_wait.set_wait_time(time)
	timer_wait.start()
	
	
func start_from_signal(body: Node) -> void:
	if body.is_in_group("Player"):
		start_cutscene(false)
	
	
func set_cutscene_file(value: String) -> void:
	cutscene_file = value
	
	
func _on_TimerWait_timeout() -> void:
	run_cutscene_step()
