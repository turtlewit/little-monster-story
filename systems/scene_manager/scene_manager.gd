extends Node


signal load_started()
signal load_progress(percent)
signal load_finished()

var level_loader: ResourceInteractiveLoader
var first_process := true;


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)


func poll() -> int:
	return level_loader.poll()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# To avoid hang before loading screen appears if the first poll() takes a long time
	if first_process:
		first_process = false
		return
	
	var result := poll()
	
	emit_signal("load_progress", float(level_loader.get_stage()) / float(level_loader.get_stage_count()))
	
	if result == ERR_FILE_EOF:
		var scene := level_loader.get_resource() as PackedScene
		Controller.construct_timer(0.001, self, "switch_to_scene", [scene])
		set_process(false)


func switch_to_scene(scene: PackedScene) -> void:
	var root: Node = scene.instance() # TODO: make threaded?
	
	yield(get_tree(), "idle_frame")
	
	get_tree().call("_change_scene", root)
	
	level_loader = null
	emit_signal("load_finished")
	$CanvasLayer/ColorRect.visible = false
	
	# Autosave on level load
	if get_tree().current_scene.filename in ["res://areas/new_level_1/level_1.tscn", "res://areas/level_1/shortened.tscn"]:
		Controller.construct_timer(1, self, "autosave")
	else:
		print("main menu")


# This function isn't the canonical autosave function,
# if you want to autosave, call SaveManager.save(-1)
func autosave() -> void:
	SaveManager.call_deferred("save", -1)


func change_scene(path: String) -> void:
	if level_loader != null:
		push_error("Attempted to load scene %s while already loading a scene!" % path)
		return
	
	level_loader = ResourceLoader.load_interactive(path, "PackedScene")
	
	$CanvasLayer/ColorRect.visible = true
	
	var old_root: Node = get_tree().current_scene
	old_root.queue_free()
	get_tree().current_scene = null
	
	emit_signal("load_started")
	
	yield(get_tree(), "idle_frame")
	first_process = true
	set_process(true)
