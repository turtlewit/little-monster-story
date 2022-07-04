tool
extends EditorPlugin



func _enter_tree() -> void:
	add_custom_type("PropArea", "Spatial", preload("res://addons/prop_area/prop_area.gdns"), null)


func _exit_tree() -> void:
	remove_custom_type("PropArea")
