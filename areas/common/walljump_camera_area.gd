extends "res://areas/common/active_camera_area.gd"


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
export var distance := 5.0


func _position_camera(delta: float) -> Transform:
	var target := Transform()
	target.basis = Basis(global_transform.basis.get_rotation_quat() * Quat(Vector3(0, 0, 0)))
	target.origin = global_transform.origin
	target.origin.y = player.global_transform.origin.y + (2.0 * (distance / 5.0))
	target.origin -= global_transform.basis.xform(Vector3.FORWARD) * distance
	var looking_at := target.looking_at(player.global_transform.origin, Vector3.UP)
	target.basis = Basis(target.basis.get_euler() * Vector3(0, 1, 1) + looking_at.basis.get_euler() * Vector3(1, 0, 0))
	return target
