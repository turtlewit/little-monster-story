extends Spatial

signal count_total_collectibles()
signal small_collectible_collected(total_count)
signal large_collectible_collected(total_count)

var small_collectibles := 0
var large_collectibles := 0

var lighting_state: int = 0


func _ready() -> void:
	var save_data := SaveManager.get_save_dict("level_progress_shortened")
	small_collectibles = save_data.get("small_collectibles", 0)
	large_collectibles = save_data.get("large_collectibles", 0)
	emit_signal("small_collectible_collected", small_collectibles)
	emit_signal("large_collectible_collected", large_collectibles)
	
	Controller.reset_collectible_totals()
	
	call_deferred("emit_signal", "count_total_collectibles")


func collect_small_collectible() -> void:
	small_collectibles += 1
	emit_signal("small_collectible_collected", small_collectibles)


func collect_large_collectible() -> void:
	large_collectibles += 1
	emit_signal("large_collectible_collected", large_collectibles)
	
	
func finish_level_prototype() -> void:
	PlayerState.is_player_input_active = false
	PlayerState.is_player_camera_active = false
	MouseModeStack.push_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	($CanvasLayer2/ThanksForPlaying as TextureRect).show()


func _save() -> void:
	var save_data := SaveManager.get_save_dict("level_progress_shortened")
	save_data["small_collectibles"] = small_collectibles
	save_data["large_collectibles"] = large_collectibles
	save_data["lighting_state"] = lighting_state
