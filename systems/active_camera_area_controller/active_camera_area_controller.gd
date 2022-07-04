extends Node


var current_areas := Array()
var player_camera: PlayerCamera

onready var camera := Camera.new()


func _ready() -> void:
	camera.current = false
	camera.far = 1000
	add_child(camera)
	set_physics_process(false)


func get_area_changing_states() -> Array:
	var all_increasing := true
	var all_decreasing := true
	for area in current_areas:
		all_increasing = all_increasing and area.increasing
		all_decreasing = all_decreasing and area.decreasing
	
	return [all_increasing, all_decreasing]


func _physics_process(delta: float) -> void:
	var avg_rotation := Vector3()
	var avg_position := Vector3()
	
	var total_percents := 0.0
	var max_percent := 0.0
	
	for area in current_areas:
		total_percents += area.original_target_lerp_percent
		max_percent = max(max_percent, area.original_target_lerp_percent)
	
	var states := get_area_changing_states()
	var all_increasing: bool = states[0]
	var all_decreasing: bool = states[1]
	
	var player_lerp_percent := 1.0
	if all_decreasing or all_increasing:
		player_lerp_percent = float(max_percent)

	
	if total_percents > 0.0:
		total_percents = 1.0 / total_percents
	
	for area in current_areas:
		avg_position += area.target_transform.origin * (area.original_target_lerp_percent) * total_percents
		avg_rotation += area.target_transform.basis.get_euler() * (area.original_target_lerp_percent) * total_percents
	
	camera.global_transform.origin = lerp(player_camera.global_transform.origin, avg_position, player_lerp_percent)
	camera.global_transform.basis = Basis(Quat(player_camera.global_transform.basis.get_rotation_quat()).slerp(Quat(avg_rotation), player_lerp_percent))


func add_area(area: Area) -> void:
	if len(current_areas) == 0:
		player_camera = area.player_camera
		set_physics_process(true)
		area.player.set("use_camera_basis", true)
		camera.global_transform = player_camera.global_transform
		camera.current = true
	current_areas.append(area)


func remove_area(area: Area) -> void:
	current_areas.erase(area)
	if len(current_areas) == 0:
#		player_camera.rotation_offset = player_camera.player.rotation.y
		player_camera.current = true
		player_camera = null
		set_physics_process(false)
		area.player.set("use_camera_basis", false)
	else:
		var states := get_area_changing_states()
		var all_increasing: bool = states[0]
		if all_increasing:
			for area in current_areas:
				area.original_target_lerp_percent = 1.0
