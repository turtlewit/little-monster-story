extends Node


onready var original_density: int = get_parent().get("number_of_instances")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Settings.connect("setting_modified", self, "_on_setting_updated")
	var density = Settings.settings["video"]["grass_density"]
	if density != 0:
		update_density(density)
	yield(get_tree(), "idle_frame")
	for child in get_parent().get_children():
		if child is MultiMeshInstance:
			child.layers = 2


func _on_setting_updated(section: String, setting: String, value) -> void:
	if section == "video" and setting == "grass_density":
		update_density(value)


func update_density(density: int) -> void:
	var new_density = original_density
	match density:
		1:
			new_density /= 2
		2:
			new_density /= 8
		3:
			new_density = 0
	get_parent().set("number_of_instances", new_density)
