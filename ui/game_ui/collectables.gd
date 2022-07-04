extends HBoxContainer


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var scene := get_tree().current_scene
	if scene.has_signal("small_collectible_collected") and scene.has_signal("large_collectible_collected"):
		scene.connect("small_collectible_collected", self, "_on_small_collectable_collected")
		scene.connect("large_collectible_collected", self, "_on_large_collectable_collected")


func _on_small_collectable_collected(amount: int) -> void:
	$SmallCollectiblesText.text = str(amount)


func _on_large_collectable_collected(amount: int) -> void:
	$LargeCollectiblesText.text = str(amount)
