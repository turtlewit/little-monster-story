extends Control


func _enter_tree() -> void:
	$CenterContainer/Buttons/NewGame.auto_grab = true
	$CenterContainer/Buttons/NewGame.grab_focus_deferred()
	
	
func _ready() -> void:
	PlayerState.is_player_input_active = true
	

func quit() -> void:
	get_tree().quit()


func button_pressed(position: int) -> void:
	match position:
		0: # New Game
			$SavePanelLayer/MouseBlock.show()
			$SavePanelLayer/SavePanel.open($SavePanelLayer/SavePanel.Mode.NewGame)
			
		1: # Load Game
			$SavePanelLayer/MouseBlock.show()
			$SavePanelLayer/SavePanel.open($SavePanelLayer/SavePanel.Mode.LoadGame)
			
		2: # Settings
			$SettingsPanelLayer/MouseBlock.show()
			$SettingsPanelLayer/SettingsPanel.show()
			
		3: # Credits
			$CreditsLayer/MouseBlock.show()
			$CreditsLayer/CreditsPanel.show()
			
		_: # Quit
			$SavePanelLayer/MouseBlock.show()
			$FadeLayer/AnimationPlayer.play("Fadeout")
