extends Object
class_name TweenRotationHelper


var original_value: Quat
var target_value: Quat
var target: Object
var target_property: NodePath # Should be euler rotation (radians)


# This method does not start the tween. Callee must call start() on tween.
func _init(tween: Tween, object: Object, property: NodePath, initial_value: Quat, final_value: Quat, duration: float, trans_type: int = 0, ease_type: int = 2, delay: float = 0) -> void:
	original_value = initial_value
	target_value = final_value
	target = object
	target_property = property
	
	tween.interpolate_method(self, "_interpolate", 0, 1, duration, trans_type, ease_type, delay)
	tween.connect("tween_completed", self, "_on_tween_completed")


func _interpolate(percent: float) -> void:
	target.set(target_property, original_value.slerp(target_value, percent).get_euler())


func _on_tween_completed(object: Object, key: NodePath) -> void:
	if object == self:
		call_deferred("free")
