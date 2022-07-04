extends Spatial


export var material: ShaderMaterial


func _physics_process(delta: float) -> void:
	material.set_shader_param("player_position", global_transform.origin)
