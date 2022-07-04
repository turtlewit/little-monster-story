extends Node


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Settings.connect("setting_modified", self, "_on_setting_changed")


func _on_setting_changed(section: String, setting: String, value) -> void:
	match section:
		"video":
			match setting:
				"fxaa":
					$CanvasLayer/Control.visible = value
