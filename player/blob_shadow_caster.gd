extends Spatial

const EPSILON := 0.001

export(int, LAYERS_3D_PHYSICS) var collision_mask: int
export var ray_distance: float = 1000

onready var blob_shadow := $BlobShadow as Spatial


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	call_deferred("remove_child", blob_shadow)
	get_tree().current_scene.call_deferred("add_child", blob_shadow)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var state := get_world().direct_space_state
	
	var result := state.intersect_ray(global_transform.origin, global_transform.origin - Vector3(0, ray_distance, 0), [get_parent()], collision_mask)
	if result:
		blob_shadow.visible = true
		blob_shadow.global_transform.origin = result["position"] + Vector3(0, EPSILON, 0)
		var b := Basis()
		b.y = result["normal"]
		b.x = b.y.cross(blob_shadow.global_transform.basis.z)
		b.z = blob_shadow.global_transform.basis.x.cross(b.y)
		b = b.orthonormalized()
		blob_shadow.global_transform.basis = b;
	else:
		blob_shadow.visible = false
