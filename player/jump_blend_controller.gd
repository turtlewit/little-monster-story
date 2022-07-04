extends Node


const transition_velocity := 8.0

onready var tree: AnimationTree = get_parent()
onready var player: PlayerMovement = tree.get_parent()


func _process(delta: float) -> void:
	var velocity := clamp(player.linear_velocity.y, -transition_velocity, transition_velocity)
	velocity = velocity / transition_velocity
	velocity = (velocity + 1.0) * 2.0
	velocity = 1.0 - velocity
	tree.set("parameters/MainAction/JumpBlendTree/FlyFallBlend/blend_amount", velocity)
