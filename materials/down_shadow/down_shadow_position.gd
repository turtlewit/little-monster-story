extends Spatial


var material: ShaderMaterial = preload("res://shaders/down_shadow.tres")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	material.set_shader_param("shadow_position", global_transform.origin)
	
	var space_state := get_world().direct_space_state
	var result: Dictionary = space_state.intersect_ray(global_transform.origin, (global_transform.origin * Vector3(1, 0, 1)) + Vector3(0, -10, 0))
	
	if result:
		material.set_shader_param("raycast_position", result.position.y)
