extends Button


export var save_number: int setget set_save_number
var has_data := false


func _ready() -> void:
	set_save_number(save_number)


func set_save_number(value: int) -> void:
	save_number = value


func set_save_data(save_data: Dictionary) -> void:
	$Data.text = save_data.get("metadata", Dictionary()).get("time", "ERROR")
	has_data = true
