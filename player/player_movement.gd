extends KinematicBody
class_name PlayerMovement

enum State {
	Ground,
	PreJump,
	Jumping,
	Tethered,
	Sliding,
	Ledge,
}

const TetherJoint := preload("res://player/tether_joint.tscn")
const PlayerRigidbody := preload("res://player/player_rigidbody.tscn")
const RespawnParticles := preload("res://effects/particles_respawn.tscn")

const jump_force: float = 15.0
const forward_jump_force: float = 4.0
const backward_jump_force: float = 3.0
const backward_jump_height: float = 3.0
const air_control: float = 4.0
const max_jump_hold_time: float = 0.9
const min_jump_hold_time: float = .1
const gravity := Vector3(0, -22, 0)
const spin_multiplier: float = 1.5
const max_turn_angle: float = 15.0
const min_slope_angle: float = PI/6
const max_jump_queue_time: float = 0.2
const respawn_add_height: float = 1.0
const max_vertical_velocity: float = 30.0
const max_horizontal_velocity: float = 20.0
const horizontal_tongue_boost: float = 1.0
const vertical_tongue_boost: float = 6.0
const slide_acceleration: float = 3.0
const slide_max_velocity: float = 10.0
const ledge_climb_offset := Vector3(0, 0.225, -.2)

var state_transitions := [
	funcref(self, "trans_default"), # Ground
	funcref(self, "trans_prejump"), # PreJump
	funcref(self, "trans_jumping"), # Jumping
	funcref(self, "trans_default"), # Tethered
	funcref(self, "trans_sliding"), # Sliding
	funcref(self, "trans_ledge"), # Ledge
]

var state_out_transitions := [
	funcref(self, "trans_out_default"), # Ground
	funcref(self, "trans_out_prejump"), # PreJump
	funcref(self, "trans_out_jumping"), # Jumping
	funcref(self, "trans_out_default"), # Tethered
	funcref(self, "trans_out_default"), # Sliding
	funcref(self, "trans_out_ledge"), # Ledge
]

var state: int = State.Jumping setget set_state
func set_state(value: int) -> void:
	(state_out_transitions[state] as FuncRef).call_func()
	(state_transitions[value] as FuncRef).call_func(state)
	PlayerState.emit_signal("movement_state_changed", state, value)
	state = value

var linear_velocity := Vector3()
var angular_velocity := Vector3()

# x: [-1, 1], represents spin
# y: [-1, 1], represents forward force
var wish_direction := Vector2()
var jump_time: float = 0
var queue_jump := false
var moving_platform: RigidBody = null
var moving_platform_offset := Transform()
var last_safe_position := Transform()
var last_jump_button_release_time: float = INF
var rigidbody: RigidBody
var tether_joint: Joint
var touching_wall: bool = false
var wall_normal := Vector3()
var point_on_wall := Vector3()
var wall_local_normal := Vector3()
var continue_sliding := false
var use_camera_basis := false
var respawning := false

onready var model := $Frog as Spatial
onready var original_position := global_transform.origin
onready var hypno_particles := $ParticlesPivot/HypnoParticles as CPUParticles
onready var hypno_particles_pivot := $ParticlesPivot as Spatial
onready var hypno_area_box := $ParticlesPivot/HypnoArea/CollisionShape as CollisionShape
onready var sound_jump := $SoundJump as AudioStreamPlayer
onready var sound_land := $SoundLand as AudioStreamPlayer
onready var camera_pivot := $CameraPivot as Spatial
onready var jump_queue_timer := $JumpQueueTimer as Timer
onready var jump_button_release_timer := CountUpTimer.new()
onready var last_ground_position := global_transform.origin
onready var animation_tree := $AnimationTree as AnimationTree


func _ready() -> void:
	PlayerState.connect("input_state_changed", self,"_on_input_state_changed")
	PlayerState.connect("state_changed", self, "_on_player_state_changed")
	PlayerState.connect("respawn", self, "_on_respawn")
	PlayerState.connect("landed", self, "_on_land")
	PlayerState.state = PlayerState.State.Active
	MouseModeStack.push_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	jump_queue_timer.wait_time = max_jump_queue_time
	jump_queue_timer.one_shot = true
	
	add_child(jump_button_release_timer)
	
	$JumpChargeTween.connect("tween_all_completed", self, "_on_tween_finish")
	
	if PlayerState.load_position and SaveManager.save_data.has("player"):
		PlayerState.load_position = false
		var data := SaveManager.get_save_dict("player")
		if data.has("transform"):
			pass
		if data.has("last_safe_position"):
			global_transform = SaveManager.load_complex_type(data["last_safe_position"], TYPE_TRANSFORM)
			transform.origin += Vector3(0, 1, 0)
			last_safe_position = SaveManager.load_complex_type(data["last_safe_position"], TYPE_TRANSFORM)
		
		camera_pivot.transform.origin = transform.origin


func _save() -> void:
	var data := SaveManager.get_save_dict("player")
	data["transform"] = transform
	if state == State.Ground or state == State.PreJump:
		data["last_safe_position"] = global_transform
	else:
		data["last_safe_position"] = last_safe_position


func _on_respawn() -> void:
	respawning = true
	PlayerState.set_is_player_input_active(false)
	transform = last_safe_position
	transform.origin += Vector3(0, respawn_add_height, 0)
	linear_velocity = Vector3()
	
	(get_node("SoundRespawn") as AudioStreamPlayer).play()
	var particles := RespawnParticles.instance()
	particles.set_global_transform(get_global_transform())
	get_tree().get_root().add_child(particles)
	
	set_state(State.Jumping)
	camera_pivot.transform.origin = transform.origin
	
	
func _on_land() -> void:
	if respawning:
		PlayerState.set_is_player_input_active(true)
		respawning = false


func _on_input_state_changed(enable: bool) -> void:
	set_process(enable)
	#set_physics_process(enable)
	set_process_input(enable)
	set_process_unhandled_input(enable)
	if not enable:
		wish_direction = Vector2.ZERO


func _on_player_state_changed(_old: int, _new: int) -> void:
	pass


func trans_default(_prev: int) -> void:
	pass


func trans_out_default() -> void:
	pass


func trans_prejump(prev: int) -> void:
	if prev == State.Sliding:
		continue_sliding = true
	else:
		continue_sliding = false


func trans_out_prejump() -> void:
	$JumpChargeTween.remove_all()
	PlayerState.emit_signal("jump_hold_ended", jump_time)


func trans_jumping(prev: int) -> void:
	if moving_platform:
		moving_platform.set("other_body", null)
	if prev != State.Ledge:
		animation_tree["parameters/MainAction/playback"].travel("JumpBlendTree")
	PlayerState.set_is_player_on_ground(false)


func trans_out_jumping() -> void:
	animation_tree["parameters/MainAction/playback"].travel("Idle-loop")


func trans_sliding(_prev: int) -> void:
	linear_velocity = Vector3()


func trans_ledge(_prev: int) -> void:
	rotation.x = 0;
	animation_tree["parameters/MainAction/playback"].travel("Climb")
	Controller.construct_timer(1.53, self, "_on_climb_animation_finished")
	model.translation.z = -0.13
	model.translation.y = (-0.13 * 1) + 0.01


func _on_climb_animation_finished() -> void:
	call_deferred("fall")


func trans_out_ledge() -> void:
	model.translation.z = 0
	model.translation.y = 0
	global_transform.origin += transform.basis.xform(ledge_climb_offset)
	rotation.x = 0


func pre_jump() -> void:
	PlayerState.emit_signal("jump_hold_started")
	set_state(State.PreJump)
	jump_time = 0
	$JumpChargeTween.interpolate_property(self, "jump_time", 0.0, 0.8, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	$JumpChargeTween.start()


func _on_tween_finish() -> void:
	if state == State.PreJump:
		$JumpChargeTween.interpolate_property(self, "jump_time", jump_time, 0.8 - jump_time, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
		$JumpChargeTween.start()


func fall() -> void:
	linear_velocity = Vector3()
	set_state(State.Jumping)


func jump() -> void:
	sound_jump.set_pitch_scale(rand_range(0.98, 1.05))
	sound_jump.play()
	
	if touching_wall:
		var norm := wall_normal
		if moving_platform:
			norm = moving_platform.global_transform.basis.xform(wall_local_normal)
		norm.y = 2
		norm = norm.normalized()
		linear_velocity = norm * (min(max_jump_hold_time, jump_time + min_jump_hold_time) / max_jump_hold_time) * jump_force
	else:
		linear_velocity = Vector3(0, (min(max_jump_hold_time, jump_time + min_jump_hold_time) / max_jump_hold_time) * jump_force, 0)
		
		var forward = -global_transform.basis.z
		if forward.y < 0:
			forward.y = 0
			forward = forward.normalized()
		
		var horizontal_charge_influence: float = 1
		if last_jump_button_release_time > .15:
			horizontal_charge_influence = min(1, jump_time + .1 / 0.3)
		linear_velocity += forward * (wish_direction.length()) * forward_jump_force * horizontal_charge_influence
		
		if not moving_platform or moving_platform is preload("res://areas/common/moving_platforms/bouncy_platform.gd"):
			last_safe_position = transform
		

		
		last_ground_position = global_transform.origin
	
	set_state(State.Jumping)
	look_at(translation + ((-transform.basis.z).slide(Vector3.UP).normalized()), Vector3.UP)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_jump"):
		last_jump_button_release_time = jump_button_release_timer.stop()
		match state:
			State.Ground:
				pre_jump()
			State.Jumping:
				queue_jump = true
				jump_queue_timer.start()
	
	if event.is_action_released("move_jump") and state == State.PreJump:
		jump()

	if event.is_action_released("move_jump"):
		jump_button_release_timer.start()
	
	if state == State.Tethered and event.is_action_released("action_tongue"):
		untether()

func _process(delta: float) -> void:
	if state == State.Ground || state == State.PreJump || (state == State.Jumping):
		wish_direction.x = -Input.get_action_strength("move_right") + Input.get_action_strength("move_left")
		wish_direction.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	
	if state == State.PreJump:
		PlayerState.emit_signal("jump_hold_updated", jump_time)
#		jump_time += delta
	
	if state == State.Ground and queue_jump == true:
		queue_jump = false
		if Input.is_action_pressed("move_jump"):
			pre_jump()
		else:
			jump()

	hypno_particles_pivot.set_rotation_degrees(model.get_rotation_degrees())
	PlayerState.is_player_using_hypno = Input.is_action_pressed("action_hypno")
	hypno_particles.set_emitting(PlayerState.is_player_using_hypno)
	hypno_area_box.set_disabled(not PlayerState.is_player_using_hypno)
	
	if state == State.Jumping and Input.is_action_pressed("action_tongue"):
		tether()


func _physics_process(delta: float) -> void:
	match state:
		State.Ground:
			turn(delta)
		State.PreJump:
			if not touching_wall:
				turn(delta)
			if continue_sliding:
				slide(delta)
		State.Jumping:
			turn(delta)
			jumping(delta)
		State.Tethered:
			move_with(rigidbody)
			#turn(delta)
		State.Sliding:
			slide(delta)
	if moving_platform:
		update_platform_offset()


func move_with(other: Spatial) -> void:
	var ot = other.global_transform
#	ot.basis = Basis(ot.basis.get_rotation_quat())
	global_transform.origin = ot.xform(moving_platform_offset.origin)

func rotate_with(other: Spatial) -> void:
	var ot = other.global_transform
#	ot.basis = Basis(ot.basis.get_rotation_quat())
	global_transform.basis = Basis(ot.basis.get_rotation_quat()) * moving_platform_offset.basis

func update_offset(from: Spatial) -> void:
	var ot = from.global_transform
	# work around really dumb thing about xform_inv and xform not treating scale the same way
	# heck
	moving_platform_offset.origin = ot.affine_inverse().xform(global_transform.origin)
	moving_platform_offset.basis = Basis(ot.basis.get_rotation_quat()).inverse() * global_transform.basis


func move_with_platform() -> void:
	if state in [State.Ground, State.PreJump, State.Ledge]:
		move_with(moving_platform)
		rotate_with(moving_platform)
		if state != State.Ledge:
			check_angle()


func update_platform_offset() -> void:
	if state != State.Tethered:
		update_offset(moving_platform)


func turn(_delta: float) -> void:
#	angular_velocity = Vector3(0, wish_direction.x * spin_multiplier, 0)
#	rotation += angular_velocity * delta * spin_multiplier
	if wish_direction.length() > 0:
		var pivot_transform: Transform = camera_pivot.transform
		if use_camera_basis:
			#pivot_transform = camera_pivot.get_node("PlayerCamera").global_transform
			pivot_transform = get_viewport().get_camera().global_transform
		pivot_transform = pivot_transform.rotated(pivot_transform.basis.x, -camera_pivot.rotation.x)
		var cam_rot := pivot_transform.basis.get_euler().y
		var a := atan2(wish_direction.y, -wish_direction.x) + cam_rot - PI/2
		var nz := Vector3(0, -transform.basis.y.z, transform.basis.y.y)
		var a2 := transform.basis.z.angle_to(nz)
		if transform.basis.z.x > 0:
			a -= a2
		else:
			a -= (2 * PI) - a2
		rotate_object_local(Vector3.UP, a)
		move_and_slide(Vector3())


# The y angle is the angle from a right triangle, 
# where the length is the hypotnuse of the triangle 
# x and z make.
func get_y_angle_from_normal(n: Vector3) -> float:
	return atan2(n.y, sqrt(pow(n.x, 2) + pow(n.z, 2)))


func slide(delta: float) -> void:
	look_at(global_transform.origin + (Vector3.UP.slide(wall_normal.normalized()).normalized()), wall_normal)
	
	linear_velocity.y = min(linear_velocity.y - (slide_acceleration * delta), slide_max_velocity);
	var result := move_and_collide(Vector3(0, linear_velocity.y, 0) * delta)
	
	if result and get_y_angle_from_normal(result.normal) >= min_slope_angle:
		touching_wall = false
		fall()
		return
	elif result:
		move_and_slide(result.remainder / delta)
	
	var distance := (global_transform.origin - point_on_wall).dot(wall_normal)
	var point_along_wall := global_transform.origin - (distance * wall_normal)
	
	result = move_and_collide(point_along_wall - global_transform.origin)
	if result and get_y_angle_from_normal(result.normal) < (-PI/3):
		touching_wall = false
		fall()
		return
	elif result:
		wall_normal = result.normal
		point_on_wall = result.position
	
	if not result:
		touching_wall = false
		fall()
		return;
	
	var ledge := check_for_ledge()
	
	
	if result and ledge and get_y_angle_from_normal(result.normal) > -0.01:
		#print(get_y_angle_from_normal(result.normal))
		set_state(State.Ledge)
		return
	
	if Input.is_action_pressed("move_jump") and state == State.Sliding:
		pre_jump()


func check_for_ledge() -> bool:
	var space := get_world().direct_space_state
	var query := PhysicsShapeQueryParameters.new()
	var pos := global_transform.origin + global_transform.basis.xform(ledge_climb_offset * Vector3(1, -1, 1))
	query.set_shape($CollisionShape.shape)
	query.transform.origin = pos
	var result := space.collide_shape(query, 1)
	if len(result) == 0:
		var ray_target0 := pos
		ray_target0.x = global_transform.origin.x
		ray_target0.z = global_transform.origin.z
		var ray_target1 := ray_target0
		ray_target1.y = global_transform.origin.y
		
		var ray0 = space.intersect_ray(pos, ray_target0, [self])
		if ray0:
			return false
		
		var ray1 = space.intersect_ray(ray_target0, ray_target1, [self])
		if ray1:
			return false
		
		return true
	return false


func jumping(delta: float) -> void:
	linear_velocity += gravity * delta
	linear_velocity += -transform.basis.z * wish_direction.length() * air_control * delta
	var rel := linear_velocity * delta
	
	var result := move_and_collide(rel)
	touching_wall = false
	if result:
		var normal := result.normal
		var remainder := result.remainder
		
		if get_y_angle_from_normal(normal) < min_slope_angle:
			touching_wall = true
			wall_normal = normal
			point_on_wall = result.position
			if linear_velocity.y < 0 or Input.is_action_pressed("move_jump"):
				set_state(State.Sliding)
				
			else:
				var v := move_and_slide(remainder, Vector3.UP)
				linear_velocity.x = v.x
				linear_velocity.z = v.z
				if get_y_angle_from_normal(normal) < (-PI / 3):
					linear_velocity.y = v.y
				return
		
		if Input.is_action_pressed("move_jump"):
			pre_jump()
						
		if moving_platform:
			moving_platform.disconnect("moved", self, "move_with_platform")
			moving_platform = null
		
		if (result.collider as Node).is_in_group("MovingPlatform"):
			result.collider.connect("moved", self, "move_with_platform")
			result.collider.set("other_body", self)
			moving_platform = result.collider as RigidBody
			if touching_wall:
				wall_local_normal = moving_platform.global_transform.basis.xform_inv(wall_normal)
		
		var new_z = transform.basis.z.slide(normal.normalized()).normalized()
		look_at(transform.origin - new_z, normal)

		move_and_slide(remainder, Vector3.UP)
		
		sound_land.set_pitch_scale(rand_range(0.95, 1.05))
		sound_land.play()
		PlayerState.set_is_player_on_ground(true)
		
		if state != State.Jumping:
			return
		
		set_state(State.Ground)
		jump_time = 0



func check_angle() -> void:
	if state == State.PreJump:
		if get_y_angle_from_normal(transform.basis.y) < (-PI / 3):
			fall()
	elif get_y_angle_from_normal(transform.basis.y) < min_slope_angle:
		fall()


func _on_JumpQueueTimer_timeout() -> void:
	queue_jump = false


func tether() -> void:
	PlayerState.is_player_tethered = true
	var position: Vector3 = $TetherShape.tether_position
	if not $TetherShape.has_tether_position:
		return
	
	set_state(State.Tethered)
	$CollisionShape.disabled = true
	$SoundSwing.call("play_swing")
	$SoundLand.play()
	
	spawn_tether_body(position, $TetherShape.tether_object)


func untether() -> void:
	PlayerState.is_player_tethered = false
	linear_velocity = rigidbody.linear_velocity * horizontal_tongue_boost
	var hv := linear_velocity * Vector3(1, 0, 1)
	if hv.length() > max_horizontal_velocity:
		linear_velocity = Vector3(0, rigidbody.linear_velocity.y, 0) + (hv.normalized() * max_horizontal_velocity)
	if rigidbody.linear_velocity.y > 0:
		linear_velocity.y = min(rigidbody.linear_velocity.y + vertical_tongue_boost, max_vertical_velocity)
	rigidbody.queue_free()
	$CollisionShape.disabled = false
	$SoundSwing.stop()
	$SoundJump.play()
	set_state(State.Jumping)


func spawn_tether_body(tether_position: Vector3, colliding_object: Spatial) -> void:
	var tether_object := Spatial.new()
	colliding_object.add_child(tether_object)
	tether_object.global_transform.origin = tether_position
	
	rigidbody = PlayerRigidbody.instance()
	rigidbody.add_to_group("Player")
	rigidbody.collision_layer = collision_layer
	rigidbody.collision_mask = collision_mask
	rigidbody.translation = global_transform.origin
	rigidbody.linear_velocity = linear_velocity
	rigidbody.set("tether", tether_object)
	rigidbody.set("tongue_length", rigidbody.translation.distance_to(tether_position))
	rigidbody.set("ground_position", last_ground_position)
	rigidbody.player = self
	
	get_tree().current_scene.add_child(rigidbody)
	
	moving_platform_offset = Transform()
