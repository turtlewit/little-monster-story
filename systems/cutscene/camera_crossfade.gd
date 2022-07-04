class_name CameraCrossfade
extends ViewportContainer

var old_camera_ref: Camera = null
var camera_clone: Camera = null

func _process(_delta: float) -> void:
	if camera_clone != null:
		camera_clone.set_global_transform(old_camera_ref.get_global_transform())
		
		
func crossfade(old_camera: Camera, new_camera: Camera, time: float) -> void:
	old_camera_ref = old_camera
	var viewport := get_node("Viewport") as Viewport
	viewport.set_size((get_tree().get_root() as Viewport).get_size())
	var camera := old_camera.duplicate() as Camera
	camera.set_script(null)
	viewport.add_child(camera)
	camera_clone = camera
	old_camera.set_current(false)
	new_camera.set_current(true)
	
	var tween := get_node("TweenFade") as Tween
	tween.interpolate_property(self, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), time)
	tween.start()


func _on_TweenFade_tween_all_completed() -> void:
	queue_free()
