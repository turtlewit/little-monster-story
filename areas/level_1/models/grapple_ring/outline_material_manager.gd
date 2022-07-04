extends Node


const outline_shader := preload("res://materials/outline.shader")

var original_material: Material
var outline_material: ShaderMaterial


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var parent := get_parent() as MeshInstance
	original_material = parent.get_surface_material(0)
	outline_material = ShaderMaterial.new()
	outline_material.shader = outline_shader
	outline_material.set_shader_param("grow", 0.1)
	outline_material.next_pass = original_material
	if original_material == null:
		outline_material.next_pass = SpatialMaterial.new()


func enable_outline() -> void:
	var parent := get_parent() as MeshInstance
	parent.set_surface_material(0, outline_material)


func disable_outline() -> void:
	var parent := get_parent() as MeshInstance
	parent.set_surface_material(0, original_material)
