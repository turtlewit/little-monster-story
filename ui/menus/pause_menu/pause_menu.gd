class_name PauseMenu
extends CanvasLayer

signal menu_closed()

onready var button_resume := $Base/CenterContainer/Buttons/Button1 as ChoiceButton
onready var button_save := $Base/CenterContainer/Buttons/Button2 as ChoiceButton
onready var button_options := $Base/CenterContainer/Buttons/Button3 as ChoiceButton
onready var button_exit := $Base/CenterContainer/Buttons/Button4 as ChoiceButton
onready var buttons := [button_resume, button_save, button_options, button_exit]


func _enter_tree() -> void:
	var resume := $Base/CenterContainer/Buttons/Button1 as ChoiceButton
	resume.auto_grab = true


func _ready() -> void:
	for but in buttons: # hehe, but
		(but as ChoiceButton).connect("button_pressed", self, "press_button")
		
	var tween := $Base/TweenBackground as Tween
	tween.interpolate_property($Base/ColorRect as ColorRect, "color", Color(0, 0, 0, 0), Color(0, 0, 0, 0.5), 0.5)
	tween.start()
	
	MouseModeStack.push_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	button_resume.grab_focus_deferred()
	
	get_tree().paused = true


func _exit_tree() -> void:
	get_tree().paused = false
	MouseModeStack.pop_mouse_mode()
	
	
func set_collectible_totals(small_total: int, large_total: int) -> void:
	var small_label := $Base/Collectibles/HBoxContainer/SmallCollectiblesText as Label
	var large_label := $Base/Collectibles/HBoxContainer/LargeCollectiblesText as Label
	if small_total == 0 and large_total == 0:
		small_label.set_text("0 / 0")
		large_label.set_text("0 / 0")
	else:
		small_label.set_text("%s / %s" % [get_tree().current_scene.small_collectibles, small_total])
		large_label.set_text("%s / %s" % [get_tree().current_scene.large_collectibles, large_total])


func press_button(index: int) -> void:
	match index:
		0: # Resume
			#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			var tween := close_menu()
			yield(tween, "tween_all_completed")
			emit_signal("menu_closed")
			queue_free()
			
		1: # Save
			$Base/SavePanelLayer/SavePanel.open($Base/SavePanelLayer/SavePanel.Mode.SaveGame)
			
		2: # Options
			$Base/SettingsPanelLayer/SettingsPanel.visible = true
			
		3: # Exit
			var tween := close_menu()
			yield(tween, "tween_all_completed")
			if get_tree().current_scene.filename in ["res://areas/new_level_1/level_1.tscn", "res://areas/level_1/shortened.tscn"]:
				SaveManager.save(-1)
			get_tree().quit()


func close_menu() -> Tween:
	for but in buttons:
			(but as ChoiceButton).destroy()
			
	var tween := $Base/TweenBackground as Tween
	tween.interpolate_property($Base/ColorRect as ColorRect, "color", Color(0, 0, 0, 0.5), Color(0, 0, 0, 0), 0.5)
	tween.start()
	return tween
