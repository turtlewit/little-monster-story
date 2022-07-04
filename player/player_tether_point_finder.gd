extends Spatial


export(int, LAYERS_3D_PHYSICS) var collision_mask
export var horizontal_steps: int = 5
export var vertical_steps: int = 5
export var distance: float = 5

var visual := MeshInstance.new()
var tether_position: Vector3 setget ,get_tether_position
func get_tether_position() -> Vector3:
	if !get_has_tether_position():
		return Vector3()
	return closest_target.global_transform.origin

var tether_object: Spatial setget ,get_tether_object
func get_tether_object() -> Spatial:
	return closest_target

var has_tether_position := false setget ,get_has_tether_position
func get_has_tether_position() -> bool:
	return closest_target != null

var tether_targets := Array()
var closest_target: Spatial = null
func set_closest_target(to: Spatial) -> void:
	if closest_target:
		closest_target.propagate_call("disable_outline")
	if to:
		to.propagate_call("enable_outline")
	closest_target = to

onready var camera := $Camera as Camera



func _ready() -> void:
	visual.mesh = SphereMesh.new()
	visual.mesh.radial_segments = 4
	visual.mesh.rings = 2
	visual.mesh.radius = 0.25
	visual.mesh.height = 0.5
	visual.visible = false
	get_tree().current_scene.call_deferred("add_child", visual)


func between(x: float, size: float) -> bool:
	var a := size / 2.0
	var b := -size / 2.0
	return x >= b and x <= a


#func _physics_process(delta: float) -> void:
#	var state := get_world().direct_space_state
#	var horizontal_step_size: float = 0
#	var vertical_step_size: float = 0
#
#	if horizontal_steps > 1:
#		horizontal_step_size = deg2rad(camera.fov) / float(horizontal_steps - 1)
#	if vertical_steps > 1:
#		vertical_step_size = deg2rad(camera.fov) / float(vertical_steps - 1)
#
#	var current_h_angle: float = 0
#	var current_v_angle: float = 0
#	visual.visible = false
#
#	var h := 0
#	var v := 0
#
#	var h_step := 0
#	var v_step := -1
#	has_tether_position = false
#
#	for i in range(pow(max(horizontal_steps, vertical_steps), 2)):
#		if between(h, horizontal_steps) and between(v, vertical_steps):
#			current_h_angle = horizontal_step_size * h
#			current_v_angle = vertical_step_size * v
#
#			var offset = Vector3(distance * tan(current_h_angle), distance * tan(current_v_angle), -distance)
#			var result = state.intersect_ray(global_transform.origin, global_transform.origin + (camera.global_transform.basis.xform(offset)), [], collision_mask)
#			if result:
#				visual.visible = true
#				visual.global_transform.origin = result["position"]
#				tether_position = result["position"]
#				tether_object = result["collider"]
#				has_tether_position = true
#				return
#
#		# cycle direction
#		if h == v or (h < 0 and h == -v) or (h > 0 and h == 1-v):
#			var temp := h_step
#			h_step = -v_step
#			v_step = temp
#
#		h += h_step
#		v += v_step


func get_closest_target() -> void:
	if len(tether_targets) == 0:
		set_closest_target(null)
		return
	
	var camera_transform := get_viewport().get_camera().global_transform
	var min_x = INF
	
	for target in tether_targets:
		var x := abs(camera_transform.xform(target.global_transform.origin).x)
		if x < min_x:
			min_x = x
			set_closest_target(target)


func _on_TetherTargetArea_body_entered(body: Node) -> void:
	tether_targets.append(body)
	get_closest_target()


func _on_TetherTargetArea_body_exited(body: Node) -> void:
	tether_targets.erase(body)
	get_closest_target()
