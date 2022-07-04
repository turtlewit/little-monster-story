extends StaticBody

signal npc_cutscene_started()
signal npc_cutscene_finished()

const CutsceneRef := preload("res://systems/cutscene/cutscene.tscn")

export(String) var npc_name := ""
export(Array, String, FILE, "*.yaml") var cutscene_files := []
export(bool) var can_hypnotize := false
export(bool) var hypno_after_dialogue := false
export(String, FILE, "*.tscn") var level_to_enter := String()

var in_area := false
var interacting := false
var hypno_activated := false
var current_cutscene := 0

var player_ref: Spatial = null

onready var original_xform := get_transform()


func _ready() -> void:
	for node in get_tree().get_current_scene().get_children():
		if node is Tutorial:
			connect("npc_cutscene_started", node, "destroy")

	
func _input(event: InputEvent) -> void:
	if in_area and not interacting and PlayerState.is_player_input_active and event.is_action_pressed("interact"):
		get_tree().set_input_as_handled()
		PlayerState.is_player_input_active = false
		interacting = true
		show_interact(false)
		emit_signal("npc_cutscene_started")
		
		var pos := get_translation()
		var player_pos := player_ref.get_translation()
		var q_to := Quat(Vector3.UP, atan2(pos.x - player_pos.x, pos.z - player_pos.z))
		var q_to_player := Quat(Vector3.UP, atan2(player_pos.x - pos.x, player_pos.z - pos.z) + deg2rad(90.0))
		var xform := Transform(q_to)
		var xform_player := Transform(q_to_player)
		xform.origin = pos
		xform_player.origin = player_pos
		tween_rotation(xform, xform_player, 0.5, false)
		
		
func tween_rotation(rot_to: Transform, rot_to_player: Transform, time: float, tween_player: bool) -> Tween:
	var tween := get_node("TweenRotate") as Tween
	TweenRotationHelper.new(tween, self, "rotation", Quat(rotation), rot_to.basis.get_rotation_quat(), time)
	if tween_player:
		TweenRotationHelper.new(tween, player_ref, "rotation", Quat(player_ref.rotation), rot_to_player.basis.get_rotation_quat(), time)
	tween.start()
	return tween


	
func start_dialogue() -> void:
	var cutscene := CutsceneRef.instance() as Cutscene
	cutscene.set_cutscene_file(cutscene_files[current_cutscene])
	get_node("..").add_child(cutscene)
	
	cutscene.start_cutscene()
	yield(cutscene, "cutscene_finished")
	interacting = false
	yield(tween_rotation(original_xform, Transform(), 0.5, false), "tween_all_completed")
	show_interact(true)
	PlayerState.is_player_input_active = true
	current_cutscene = min(current_cutscene + 1, len(cutscene_files) - 1)
	if hypno_after_dialogue:
		can_hypnotize = true
	emit_signal("npc_cutscene_finished")


func show_interact(show: bool) -> void:
	GameUI.show_interact_prompt(show, npc_name)


func _on_InteractionArea_body_entered(body: Node) -> void:
	in_area = true
	player_ref = body
	show_interact(true)


func _on_InteractionArea_body_exited(_body: Node) -> void:
	in_area = false
	show_interact(false)


func _on_TweenRotate_tween_all_completed() -> void:
	if interacting:
		start_dialogue()


func _on_HypnoArea_area_entered(area: Area) -> void:
	if can_hypnotize and not hypno_activated and area.is_in_group("Hypno"):
		PlayerState.is_player_input_active = false
		($SoundTeleport as AudioStreamPlayer).play()
		hypno_activated = true
		var transition := (load("res://ui/pixelate_transition.tscn") as PackedScene).instance() as CanvasLayer
		get_tree().get_root().add_child(transition)
		Controller.construct_timer(1.5, self, "_warp_to_level")
		

func _warp_to_level() -> void:
	SceneManager.change_scene(level_to_enter)
	PlayerState.is_player_input_active = true
