extends Node

signal lock_player(lock)

const PauseMenuRef := preload("res://ui/menus/pause_menu/pause_menu.tscn")

var flags := {
	
}

var menu_open := false

var current_total_collectibles_small := 0
var current_total_collectibles_large := 0


func _ready() -> void:
	PlayerState.connect("state_changed", self, "_on_player_state_changed")


func _input(event: InputEvent) -> void:
	if PlayerState.is_player_input_active and event.is_action_pressed("sys_pause"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		var menu := PauseMenuRef.instance() as PauseMenu
	
		get_tree().get_root().add_child(menu)
		menu.set_collectible_totals(current_total_collectibles_small, current_total_collectibles_large)
	
	if event.is_action_pressed("sys_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen


func _on_player_state_changed(_from, _to) -> void:
	pass
	
	
func reset_collectible_totals() -> void:
	current_total_collectibles_small = 0
	current_total_collectibles_large = 0
	
	
func increment_collectible(large: bool) -> void:
	if large:
		current_total_collectibles_large += 1
	else:
		current_total_collectibles_small += 1


func fade(time: float, fadein: bool, color: Color) -> void:
	var start := Color(color.r, color.g, color.b, 1 if fadein else 0)
	var end := Color(color.r, color.g, color.b, 0 if fadein else 1)
	
	var tween := get_node("TweenFade") as Tween
	tween.interpolate_property(get_node("CanvasLayer/Fade") as ColorRect, "color", start, end, time)
	tween.start()
	
	
func flag(name_: String) -> int:
	return flags[name_]
	
	
func set_flag(name_: String, value: int) -> void:
	flags[name_] = value


func play_sound_oneshot(sound: AudioStream, volume: float = 0.0, pitch: float = 1.0, bus: String = "Master") -> void:
	var oneshot := AudioStreamPlayer.new()
	oneshot.connect("finished", oneshot, "queue_free")
	oneshot.set_stream(sound)
	oneshot.set_volume_db(volume)
	oneshot.set_pitch_scale(pitch)
	oneshot.set_bus(bus)
	get_tree().get_root().add_child(oneshot)
	oneshot.play()
	
	
func play_music(music_: AudioStream, volume: float = 0.0, pitch: float = 1.0) -> void:
	var music := get_node("Music") as AudioStreamPlayer
	music.set_stream(music_)
	music.set_volume_db(volume)
	music.set_pitch_scale(pitch)
	music.play()
	
	
func fade_music(time: float, fadein: bool) -> void:
	var tween := get_node("TweenMusic") as Tween
	var music := get_node("Music") as AudioStreamPlayer
	tween.interpolate_property(music, "volume_db", -60.0 if fadein else 0.0, 0.0 if fadein else -60.0, time)
	tween.start()
	
	
func construct_tween(cleanup_safeguard: bool = true, safeguard_time: float = 5.0) -> Tween:
	var tween := Tween.new()
	tween.connect("tween_all_completed", tween, "queue_free", [], CONNECT_ONESHOT)
	
	if cleanup_safeguard:
		var timer := construct_timer(safeguard_time, tween, "queue_free")
		tween.connect("tween_all_completed", timer, "queue_free", [], CONNECT_ONESHOT)

	get_tree().get_root().add_child(tween)
	return tween


func construct_timer(time: float, target: Object, method: String, binds: Array = Array()) -> Timer:
	var timer := Timer.new()
	timer.set_wait_time(time)
	timer.set_one_shot(true)
	timer.connect("timeout", target, method, binds, CONNECT_ONESHOT | CONNECT_REFERENCE_COUNTED)
	timer.connect("timeout", timer, "queue_free", [], CONNECT_ONESHOT)
	
	get_tree().get_root().add_child(timer)
	timer.start()
	return timer
