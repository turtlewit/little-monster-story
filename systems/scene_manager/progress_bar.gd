extends TextureProgress


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneManager.connect("load_started", self, "set_value", [0.0])
	SceneManager.connect("load_progress", self, "set_value")
