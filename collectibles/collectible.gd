extends Spatial

signal collected()

export(AudioStream) var collect_sound: AudioStream
export(bool) var large := false
export(Texture) var bubble_texture: Texture = null
export(NodePath) var cutscene := NodePath()
export var magnetize_speed: float = 0.2

var collected := false
var magnetized := false
var player: Spatial = null
var tween := Tween.new()
var tween_percent: float = 0

onready var original_position = global_transform.origin


func _ready() -> void:
	get_tree().get_current_scene().connect("count_total_collectibles", self, "count_self")
	
	set_process(false)
	#if bubble_texture != null:
	#	(($Model as MeshInstance).get_surface_material(0) as ShaderMaterial).set_shader_param("vision_texture", bubble_texture)
	
	if SaveManager.save_data.has(str(get_path())):
		var data := SaveManager.get_save_dict(get_path())
		if data.get("collected", false):
			visible = false
			call_deferred("emit_signal", "collected")
			queue_free()
	
	add_child(tween)


func _process(delta: float) -> void:
	if not player:
		_on_CollectArea_body_entered(null)
	if not collected:
		global_transform.origin = original_position.linear_interpolate(player.get_global_transform().origin, tween_percent)
		
		
func count_self() -> void:
	Controller.increment_collectible(large)


func _on_CollectArea_body_entered(_body: Node) -> void:
	if not collected:
		var data := SaveManager.get_save_dict(str(get_path()))
		data["collected"] = true
		emit_signal("collected")
#	if not collected:
#		get_tree().get_current_scene().call("collect_small_collectible")
#
#		Controller.play_sound_oneshot(collect_sound, 0.0, rand_range(0.95, 1.05), "SFX")
#		($Model as Spatial).hide()
#		($AnimationPlayer as AnimationPlayer).play("Fade")
#		($TimerDestroy as Timer).start()
#		collected = true


func _on_MagnetArea_body_entered(body: Node) -> void:
	if not magnetized:
		original_position = global_transform.origin
		player = body
		tween.interpolate_property(self, "tween_percent", 0.0, 1.0, magnetize_speed, Tween.TRANS_CUBIC, Tween.EASE_IN)
		tween.start()
		set_process(true)
		magnetized = true
