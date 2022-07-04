extends Panel

export(bool) var main_menu := false

const SaveGame = preload("res://ui/menus/save_panel/savegame.gd")

enum Mode {
	SaveGame,
	LoadGame,
	NewGame,
}

signal save_game(save)
signal load_game(save)
signal new_game(save)

var mode
var old_focus: Control


func open(mode_) -> void:
	mode = mode_
	visible = true
	old_focus = get_focus_owner()
	$VBoxContainer/Save0.grab_focus()
	populate_saves()


func populate_saves() -> void:
	if not mode == Mode.LoadGame:
		$VBoxContainer/AutoSave.visible = false
	else:
		$VBoxContainer/AutoSave.visible = true
		if SaveManager.save_file_exists(-1):
			$VBoxContainer/AutoSave.set_save_data(SaveManager.get_save_data(-1))
		elif mode == Mode.LoadGame:
			$VBoxContainer/AutoSave.disabled = true
	
	for i in range(3):
		var s: SaveGame = get_node("VBoxContainer/Save%d" % i)
		if SaveManager.save_file_exists(i):
			s.set_save_data(SaveManager.get_save_data(i))
		elif mode == Mode.LoadGame:
			s.disabled = true


func _on_save_selected(save) -> void:
	var signame: String
	match mode:
		Mode.SaveGame:
			signame = "save_game"
		Mode.LoadGame:
			signame = "load_game"
		Mode.NewGame:
			signame = "new_game"
	emit_signal(signame, save)


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_cancel"):
		visible = false
		if main_menu:
			var mouse_block = get_node("../MouseBlock")
			if mouse_block:
				mouse_block.visible = false


func save_time(data: Dictionary) -> void:
	var dt := OS.get_datetime()
	data["time"] = "{year}-{month}-{day} {hour}:{minute}:{second}".format(dt)


func _on_SavePanel_load_game(save: int) -> void:
	SaveManager.load_save(save)
	
	var area = SaveManager.save_data.get("player_state", Dictionary()).get("area", null)
	if area:
		SceneManager.change_scene(area)
		PlayerState.load_position = true
	else:
		SceneManager.change_scene("res://areas/game/overworld/overworld_prototype.tscn")


func _on_SavePanel_new_game(save: int) -> void:
	var data := SaveManager.get_save_dict("metadata")
	save_time(data)
	SaveManager.save(save)
	SceneManager.change_scene("res://areas/game/overworld/overworld_prototype.tscn")


func _on_SavePanel_save_game(save: int) -> void:
	var data := SaveManager.get_save_dict("metadata")
	save_time(data)
	SaveManager.save(save)
	var s: SaveGame = get_node("VBoxContainer/Save%d" % save)
	s.set_save_data(SaveManager.save_data)


func _on_SavePanel_visibility_changed() -> void:
	if not visible and old_focus:
		old_focus.grab_focus()
