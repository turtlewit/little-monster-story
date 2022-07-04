extends MeshInstance

signal all_collectibles_collected()

export(Array, NodePath) var connected_collectibles: Array
export(Array, NodePath) var indicators: Array
export(int) var collectibles_required := 3
export(NodePath) var cutscene := NodePath()

var collected := 0
var open := false


func _ready() -> void:
	var save_data := SaveManager.get_save_dict(SaveManager.get_default_identifier(self))
	if save_data.get("open", false):
		open = true
		for indicator in indicators:
			get_node(indicator).queue_free()
		queue_free()
	else:
		for coll in connected_collectibles:
			var node := get_node(coll) as Spatial
			node.connect("collected", self, "add_collectible")
			
			
func debug_start_cutscene() -> void:
	PlayerState.is_player_input_active = false
	var cutscene_obj := get_node(cutscene) as Cutscene
	cutscene_obj.connect("cutscene_finished", PlayerState, "set_is_player_input_active", [true])
	cutscene_obj.start_cutscene(true)


func add_collectible() -> void:
	collected += 1
	
	# This is terrible
	var indicator := get_node(indicators[collected - 1]) as MeshInstance
	var grad := Gradient.new()
	grad.set_color(0, Color("#fff500"))
	grad.set_color(1, Color("#fff500"))
	var grad_tex := GradientTexture.new()
	grad_tex.gradient = grad
	(indicator.get_surface_material(0) as ShaderMaterial).set_shader_param("vision_texture", grad_tex)
	
	if collected >= collectibles_required and not open:
		open = true
		emit_signal("all_collectibles_collected")
		SaveManager.get_save_dict(SaveManager.get_default_identifier(self))["open"] = true
		PlayerState.is_player_input_active = false
			
		if not PlayerState.is_player_on_ground:
			yield(PlayerState, "landed")
		var cutscene_obj := get_node(cutscene) as Cutscene
		cutscene_obj.connect("cutscene_finished", PlayerState, "set_is_player_input_active", [true])
		cutscene_obj.start_cutscene(true)
