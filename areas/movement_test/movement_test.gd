extends Spatial

signal small_collectible_collected(total_count)
signal large_collectible_collected(total_count)

var small_collectibles := 0
var large_collectibles := 0


func collect_small_collectible() -> void:
	small_collectibles += 1
	emit_signal("small_collectible_collected", small_collectibles)


func collect_large_collectible() -> void:
	large_collectibles += 1
	emit_signal("large_collectible_collected", large_collectibles)


func _save() -> void:
	var save_data := SaveManager.get_save_dict("level_progress_movementtest")
	save_data["small_collectibles"] = small_collectibles
	save_data["large_collectibles"] = large_collectibles
