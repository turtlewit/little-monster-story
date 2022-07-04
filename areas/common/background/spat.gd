extends Spatial


const speed: float = 0.001
const rot_speed: float = 0.01

onready var rot_mul := rand_range(-1, 1)
onready var speed_mul := Vector2(rand_range(-1, 1), rand_range(-1, 1))

func _process(delta: float) -> void:
	global_transform.basis = Quat(global_transform.origin.direction_to(Vector3()), rot_speed * rot_mul * delta) * global_transform.basis.get_rotation_quat()
	global_transform = global_transform.rotated(Vector3.UP, speed * speed_mul.x * delta).rotated(Vector3.RIGHT, speed * speed_mul.y * delta)
