extends MeshInstance


export(Array, Texture) var textures: Array
export var current_texture: int = 0 setget set_current_texture

func set_current_texture(value: int) -> void:
	current_texture = value
	(material_override as ShaderMaterial).set_shader_param("base_texture", textures[current_texture])
	(material_override as ShaderMaterial).set_shader_param("shade_texture", textures[current_texture])
