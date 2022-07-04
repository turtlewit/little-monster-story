extends "res://collectibles/collectible.gd"

export (float) var volume_offset = 0.0;

func _on_CollectArea_body_entered(_body: Node) -> void:
	._on_CollectArea_body_entered(_body)
	if not collected:
		get_tree().get_current_scene().call("collect_large_collectible" if large else "collect_small_collectible")
		
		Controller.play_sound_oneshot(collect_sound, volume_offset, rand_range(0.95, 1.05), "SFX")
		($Model as Spatial).hide()
		if large:
			($IdleParticles as CPUParticles).set_emitting(false)
			($CollectParticles as CPUParticles).set_emitting(true)
			
		($AnimationPlayer as AnimationPlayer).play("Fade")
		collected = true
		
		if large and not cutscene.is_empty():
			PlayerState.is_player_input_active = false
			
			if not PlayerState.is_player_on_ground:
				yield(PlayerState, "landed")
			var cutscene_obj := get_node(cutscene) as Cutscene
			cutscene_obj.connect("cutscene_finished", PlayerState, "set_is_player_input_active", [true])
			cutscene_obj.start_cutscene(true)
			
		($TimerDestroy as Timer).start()
