extends RigidBody


const CHECK_GROUND := false

export var tongue_length: float = 6
export var maximum_tether_velocity: float = 10
export var forward_force: float = 10
export var dampening: float = 3

var tongue_scene: PackedScene = preload("res://characters/frog/tongue.tscn")
var ground_position: Vector3
var tether: Spatial
var tongue_visual: Skeleton
var player: KinematicBody

onready var camera := get_viewport().get_camera()


func _exit_tree() -> void:
	tether.queue_free()
	tongue_visual.queue_free()
	player.model.rotation = Vector3()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tether_point := tether.global_transform.origin
	var result = get_world().direct_space_state.intersect_ray(translation, translation - Vector3(0, 1000, 0))
	if result:
		ground_position = result["position"]
		var tether_height := tether_point.y - ground_position.y
		if tongue_length > tether_height and CHECK_GROUND:
			tongue_length = tether_height - 0.5
	
	var tongue_root: Spatial = tongue_scene.instance()
	tongue_visual = tongue_root.get_node("Armature/Skeleton")
	tongue_visual.get_parent().remove_child(tongue_visual)
	get_tree().current_scene.call_deferred("add_child", tongue_visual)
	tongue_root.queue_free()
	call_deferred("position_tongue_visual")
	
	for i in tongue_visual.get_bone_count():
		tongue_visual.set_bone_parent(i, -1)


func position_tongue_visual() -> void:
	var curve := Curve3D.new()
	curve.bake_interval = 0.2
	var t := global_transform
	var tt := tether.global_transform
	curve.add_point(t.origin, Vector3(), (tt.origin - t.origin) * Vector3(1, 0, 1))
	curve.add_point(tt.origin)
	
	for i in range(tongue_visual.get_bone_count()):
		var bt := Transform()
		var p := float(i) / (float(tongue_visual.get_bone_count()))
		var p2 := float(i+1) / (float(tongue_visual.get_bone_count()))
		var o := curve.interpolate_baked(p * curve.get_baked_length())
		var o2 := curve.interpolate_baked(p2 * curve.get_baked_length())
		bt.origin = o
		
		bt = bt.looking_at(o2, Vector3.UP)
		bt.basis = bt.basis.rotated(bt.basis.x, -PI/2)
		
		if i == 3:
			player.model.global_transform.basis = bt.basis.rotated(bt.basis.x, PI/2)
		bt.basis.x *= .15
		bt.basis.z *= .15
		tongue_visual.set_bone_pose(i, bt)


func _integrate_forces(state: PhysicsDirectBodyState) -> void:
	camera = get_viewport().get_camera()
	var pos := state.transform.origin
	var tether_point := tether.global_transform.origin
	
	var strength := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var hstrength := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	if abs(strength) + abs(hstrength) > 0.001:
		var spos := pos - tether_point
		var quat := Quat(camera.global_transform.basis.x, strength * (forward_force / tongue_length) * get_physics_process_delta_time())
		quat *= Quat(camera.global_transform.basis.z, hstrength * (forward_force / tongue_length) * get_physics_process_delta_time())
		spos = quat.normalized().xform(spos) + tether_point
		
		var impulse := spos - pos
		state.apply_central_impulse(impulse)
	else: # dampen velocity
		var y := state.linear_velocity.y
		var nvel := dampening * get_physics_process_delta_time()
		var m := state.linear_velocity.length() - nvel
		state.linear_velocity = state.linear_velocity.normalized() * m
		state.linear_velocity.y = y
	
	var npos := pos + (state.linear_velocity * get_physics_process_delta_time())
	
	if tether_point.distance_to(npos) > tongue_length:
		npos = tether_point + ((npos - tether_point).normalized() * tongue_length)
		var new_velocity := (npos - pos) / get_physics_process_delta_time()
		if new_velocity.length() > maximum_tether_velocity:
			new_velocity = new_velocity.normalized() * maximum_tether_velocity
		state.linear_velocity = lerp(state.linear_velocity, new_velocity, state.linear_velocity.distance_to(new_velocity) * get_physics_process_delta_time())
		#state.linear_velocity += state.total_gravity * get_physics_process_delta_time()


func _physics_process(delta: float) -> void:
	position_tongue_visual()
