extends WorldEnvironment

export(NodePath) var directional_light: NodePath

func _ready() -> void:
	var sky := environment.background_sky as ProceduralSky
	var light := get_node(directional_light) as DirectionalLight
	sky.sun_latitude = -light.rotation_degrees.x
	sky.sun_longitude = -180 - light.rotation_degrees.y
