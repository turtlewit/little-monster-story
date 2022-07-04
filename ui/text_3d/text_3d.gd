tool
extends Spatial
class_name Text3D


export(String, MULTILINE) var text: String = "Text3D" setget set_text
export var both_sides: bool = false setget set_both_sides

var mesh: MeshInstance
var viewport: Viewport
var label: Label


func _ready() -> void:
	viewport = Viewport.new()
	viewport.render_target_v_flip = true
	viewport.transparent_bg = true
	add_child(viewport)
	
	var material := SpatialMaterial.new()
	material.flags_unshaded = true
	material.flags_transparent = true
	material.albedo_color = Color(1, 1, 1, 1)
	
	mesh = MeshInstance.new()
	mesh.mesh = QuadMesh.new()
	mesh.material_override = material
	mesh.scale = Vector3(0.01, 0.01, 1)
	add_child(mesh)
	
	var center_container := CenterContainer.new()
	center_container.anchor_bottom = 1
	center_container.anchor_right = 1
	center_container.margin_bottom = 0
	center_container.margin_right = 0
	viewport.add_child(center_container)
	
	label = Label.new()
	label.text = text
	label.align = Label.ALIGN_CENTER
	center_container.add_child(label)
	
	viewport.size = label.rect_size
	material.albedo_texture = viewport.get_texture()
	material.albedo_texture.flags = Texture.FLAG_FILTER
	(mesh.mesh as QuadMesh).size = label.rect_size
	
	get_tree().root.connect("size_changed", self, "_on_size_changed")


func _on_size_changed() -> void:
	mesh.queue_free()
	viewport.queue_free()
	get_tree().root.disconnect("size_changed", self, "_on_size_changed")
	call_deferred("_ready")


func set_text(to: String) -> void:
	text = to
	if mesh:
		_set_text(to)


func _set_text(to: String) -> void:
	label.text = to
	viewport.size = label.rect_size
	(mesh.mesh as QuadMesh).size = label.rect_size


func set_both_sides(to: bool) -> void:
	both_sides = to
	if not mesh:
		return
	if to:
		(mesh.material_override as SpatialMaterial).params_cull_mode = SpatialMaterial.CULL_DISABLED
	else:
		(mesh.material_override as SpatialMaterial).params_cull_mode = SpatialMaterial.CULL_BACK
