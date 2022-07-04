extends CanvasLayer

func return_to_title(_dummy: int) -> void:
	get_tree().current_scene.fade_music()
	$AnimationPlayer.play("End2")
	$Timer.start()


func return_to_title_2() -> void:
	SceneManager.change_scene("res://areas/menu_scene.tscn")
