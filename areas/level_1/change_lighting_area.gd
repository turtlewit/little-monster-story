extends Area


export var target_rotation: Vector3
export var target_lighting_state: int = 0

var tween: Tween


func _ready() -> void:
	tween = Tween.new()
	add_child(tween)
	
	var data = SaveManager.get_save_dict("level_progress_movementtest")
	if data.get("lighting_state", 0) == target_lighting_state:
		var level = get_tree().current_scene
		var target_rot := Vector3(deg2rad(target_rotation.x), deg2rad(target_rotation.y), deg2rad(target_rotation.z))
		level.get_node("DirectionalLight").set("rotation", target_rot)
		level.set("lighting_state", target_lighting_state)
		


func transition() -> void:
	var level = get_tree().current_scene
	tween.remove_all()
	var light := level.get_node("DirectionalLight") as DirectionalLight
	var target_rot := Vector3(deg2rad(target_rotation.x), deg2rad(target_rotation.y), deg2rad(target_rotation.z))
	TweenRotationHelper.new(tween, light, "rotation", Quat(light.rotation), Quat(target_rot), 1)
	tween.start()
	level.set("lighting_state", target_lighting_state)


func _on_ChangeLightingArea_body_entered(body: Node) -> void:
	var level = get_tree().current_scene
	if body.is_in_group("Player") and level.get("lighting_state") != target_lighting_state:
		transition()
