# Save System
#
# This system manages saving and loading data. It keeps track of the active save file,
# reading and writing the json save file.
#
# JSON doesn't support Vector2/3 or integer values, so make sure to
# store vector elements separately and to convert saved integers back
# into integers when loading.
#
# save_-1.json is the autosave file. Pass -1 as save_number to access the autosave.
# 
# Example saving and loading logic:
# ```
#	if SaveManager.save_file_exists(0):
#		SaveManager.load_save(0)
#	else:
#		SaveManager.current_save_number = 0
#
#	SaveManager.save()
# ```
#
# Example node using and saving data:
# This example prints a number that increments every time the game is run.
# ```
#	var num: int = 0
#
#	func _ready() -> void:
#		# assuming a save file is active
#		if SaveManager.save_data.has("test"):
#			num = int(SaveManager.save_data["test"]["num"] as float)
#
#		print("num: %d" % num)
#
#	# Called on any node that is a part of the "Save" group when SaveManager.save() is called.
#	func _save() -> void:
#		var save_data = SaveManager.get_save_dict("test")
#		save_data["num"] = num + 1
# ```
extends Node


# save_data[identifier: String] = Dictionary
# Stored dictionary formats depend on the thing that uses them.
# Example:
#	save_data = {
#		"Player": {
#			"health": 5,
#			"position_x": 5,
#			"position_y": 4,
#		},
#	}
var save_data := Dictionary()


func save_file_exists(save_number: int) -> bool:
	var f := File.new()
	return f.file_exists("user://save_%d.json" % save_number)


# Loads the save file of the given number.
# The save file must already exist. Check if a save file
# exists with save_file_exists()
#
# This function will set save_data to the loaded contents of the save file,
# as well as set the current_save_number.
func load_save(save_number: int) -> void:
	save_data = get_save_data(save_number)



# Save the contents of save_data to the active save file (current_save_number).
# This will overwrite the previous save file.
# current_save_number must be set to a number greater than 0 before calling.
func save(save_number: int) -> void:
	var save_nodes := get_tree().get_nodes_in_group("Save")
	for node in save_nodes:
		if not node.has_method("_save"):
			push_warning("Node %d does not have a save method, but is in the save group.")
			continue
		
		node.call("_save")
	
	var save_file := File.new()
	var result := save_file.open("user://save_%d.json" % save_number, File.WRITE)
	
	if result != OK:
		push_error("Failed to open save file save_%d.json, error: %d" % [save_number, result])
		return
	
	save_file.store_line(to_json(save_data))
	
	save_file.close()


# Returns the save data for the given save number
func get_save_data(save_number: int) -> Dictionary:
	if save_number < -1:
		push_error("Save number must be greater than or equal to -1. Given: %d" % save_number)
		return Dictionary()
	
	var save_file := File.new()
	var result := save_file.open("user://save_%d.json" % save_number, File.READ)
	
	if result != OK:
		push_error("Failed to open save file save_%d.json, error: %d" % [save_number, result])
		return Dictionary()
	
	var save_contents := save_file.get_as_text()
	var parsed_contents = parse_json(save_contents)
	
	if typeof(parsed_contents) != TYPE_DICTIONARY:
		push_error("Failed to parse contents of save file save_%d.json. Check to make sure the file is formatted correctly." % save_number)
		return Dictionary()
	
	save_file.close()
	return parsed_contents


# Returns the dictionary at the given identifier if exists, or creates one and returns it.
func get_save_dict(identifier: String) -> Dictionary:
	if save_data.has(identifier):
		return save_data[identifier]
	var d := Dictionary()
	save_data[identifier] = d
	return d


func get_default_identifier(node: Node) -> String:
	return get_tree().current_scene.filename + "/" + str(node.get_path())


func vector3_from_string(s: String) -> Vector3:
	s = s.right(1).left(1) # get rid of parenthesis
	var split := s.split(", ")
	return Vector3(split[0].to_float(), split[1].to_float(), split[2].to_float())


# Converts a json representation of an object (usually a string) to that object. Not all types are supported.
func load_complex_type(value, type: int):
	match type:
		TYPE_NIL:
			push_error("Loading type of %d not supported!" % type)
		TYPE_VECTOR2:
			value = value.right(1).left(1) # get rid of parenthesis
			var split := (value as String).split(", ")
			return Vector2(split[0].to_float(), split[1].to_float())
		TYPE_RECT2:
			push_error("Loading type of %d not supported!" % type)
		TYPE_VECTOR3:
			return vector3_from_string(value)
		TYPE_TRANSFORM2D:
			push_error("Loading type of %d not supported!" % type)
		TYPE_PLANE:
			push_error("Loading type of %d not supported!" % type)
		TYPE_QUAT:
			value = value.right(1).left(1) # get rid of parenthesis
			var split := (value as String).split(", ")
			return Quat(split[0].to_float(), split[1].to_float(), split[2].to_float(), split[3].to_float())
		TYPE_AABB:
			push_error("Loading type of %d not supported!" % type)
		TYPE_BASIS:
			value = value.right(1).left(1) # get rid of parenthesis
			var split := (value as String).split(", ")
			return Basis(vector3_from_string(split[0]), vector3_from_string(split[1]), vector3_from_string(split[2]))
		TYPE_TRANSFORM:
			var split := (value as String).split(" - ")
			var bs := split[0].split(", ")
			var os := split[1].split(", ")
			var t := Transform()
			var i: int = 0
			for r in range(0, 3):
				for c in range(0, 3):
					t.basis[r][c] = bs[i].to_float()
					i += 1
			t.origin = Vector3(os[0].to_float(), os[1].to_float(), os[2].to_float())
			return t
		TYPE_COLOR:
			var split := (value as String).split(",")
			return Color(split[0].to_float(), split[1].to_float(), split[2].to_float(), split[3].to_float())
		TYPE_NODE_PATH:
			return NodePath(value)
		TYPE_RID:
			push_error("Loading type of %d not supported!" % type)
		TYPE_OBJECT:
			push_error("Loading type of %d not supported!" % type)
		TYPE_DICTIONARY:
			push_error("Loading type of %d not supported!" % type)
		TYPE_ARRAY:
			push_error("Loading type of %d not supported!" % type)
		TYPE_RAW_ARRAY:
			push_error("Loading type of %d not supported!" % type)
		TYPE_INT_ARRAY:
			push_error("Loading type of %d not supported!" % type)
		TYPE_REAL_ARRAY:
			push_error("Loading type of %d not supported!" % type)
		TYPE_STRING_ARRAY:
			push_error("Loading type of %d not supported!" % type)
		TYPE_VECTOR2_ARRAY:
			push_error("Loading type of %d not supported!" % type)
		TYPE_VECTOR3_ARRAY:
			push_error("Loading type of %d not supported!" % type)
		TYPE_COLOR_ARRAY:
			push_error("Loading type of %d not supported!" % type)
		TYPE_MAX:
			push_error("Loading type of %d not supported!" % type)
	return value

