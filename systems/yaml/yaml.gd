extends Node

const LineRegexPat := "^(\\s*)(.+):\\s*(.*)$"
const ListItemRegexPat := "^(\\s*)-\\s+(.+)$"

var line_regex := RegEx.new()
var list_item_regex := RegEx.new()

func _ready() -> void:
	line_regex.compile(LineRegexPat)
	list_item_regex.compile(ListItemRegexPat)


func decode(string: String) -> Dictionary:
	var out_dict := Dictionary()
	
	var string_array := Array(string.split("\n"))
	var stack := Array()
	var key_stack := Array()
	var current_indentation := 0
	
	for i in range(len(string_array)):
		var this_line := String(string_array[i])
		var regex_match := line_regex.search(this_line)
		var regex_match_2 := list_item_regex.search(this_line)
		
		var line_indentation := 0
		if regex_match != null:
			line_indentation = len(regex_match.get_string(1))
		elif regex_match_2 != null:
			line_indentation = len(regex_match_2.get_string(1)) + 2
			
		if line_indentation < current_indentation:
			var amount := abs(line_indentation - current_indentation) / 2
			for _j in range(amount):
				if len(stack) > 1:
					if typeof(stack[len(stack) - 2]) == TYPE_ARRAY:
						var arr := Array(stack[len(stack) - 2])
						arr.push_back(stack.back())
					else:
						stack[len(stack) - 2][key_stack.back()] = stack.back()
				else:
					out_dict[key_stack.back()] = stack.back()
					
				stack.pop_back()
				key_stack.pop_back()
				
		current_indentation = line_indentation
		
		if regex_match != null:
			var line_key := regex_match.get_string(2)
			var line_value := regex_match.get_string(3)
			if line_value.empty():
				var next_line := String(string_array[i + 1])
				if next_line.strip_edges().begins_with("-"):
					stack.push_back(Array())
				else:
					stack.push_back(Dictionary())
					
				key_stack.push_back(parse_value(line_key))
			else:
				if stack.empty():
					out_dict[parse_value(line_key)] = line_value.strip_edges()
				else:
					if typeof(stack.back()) == TYPE_ARRAY:
						var arr := Array(stack.back())
						arr.push_back(parse_value(line_value.strip_edges()))
					else:
						stack.back()[parse_value(line_key)] = parse_value(line_value.strip_edges())
		elif regex_match_2 != null:
			var line_item := regex_match_2.get_string(2)
			var arr := Array(stack.back())
			arr.push_back(parse_value(line_item))
			
	while not stack.empty():
		if len(stack) > 1:
			if typeof(stack[len(stack) - 2]) == TYPE_ARRAY:
				var arr := Array(stack[len(stack) - 2])
				arr.push_back(stack.back())
			else:
				stack[len(stack) - 2][key_stack.back()] = stack.back()
		else:
			out_dict[key_stack.back()] = stack.back()
			
		stack.pop_back()
		key_stack.pop_back()
			
	return out_dict


func parse_value(value: String):
	# Int
	if value.is_valid_integer():
		return int(value)
	
	# Float
	if value.is_valid_float():
		return float(value)
		
	# Bool
	var value_upper := value.to_upper()
	if value_upper == "TRUE":
		return true
	elif value_upper == "FALSE":
		return false
		
	# List
	if value.begins_with("["):
		var arr := Array(JSON.parse(value).get_result())
		return arr
		
	# Object
	if value.begins_with("{"):
		var dict := Dictionary(JSON.parse(value).get_result())
		return dict
		
	# String
	if value[0] == '"':
		value.erase(0, 1)
		value.erase(len(value) - 1, 1)
		
	return value


func encode(object: Dictionary) -> String:
	var out_lines := ["---"]
	encode_all(out_lines, object, 0)
	var out_string := String()
	for i in range(len(out_lines)):
		if i > 0:
			out_string += "\n"
		
		out_string += String(out_lines[i])
		
	return out_string


func encode_all(out_lines: Array, object: Dictionary, depth_level: int) -> void:
	var keys := object.keys()
	for i in range(len(keys)):
		var item = object[keys[i]]
		
		var line := String()
		for _j in range(depth_level):
			line += "  "
		
		match typeof(item):
			TYPE_ARRAY:
				var item_arr := Array(item)
				if item_arr.empty():
					line += "%s: []" % keys[i]
					out_lines.push_back(line)
				else:
					line += "%s: " % keys[i]
					out_lines.push_back(line)
					for j in range(len(item_arr)):
						var list_line := String()
						for _k in range(depth_level):
							list_line += "  "
							
						list_line += "- %s" % item_arr[j]
						out_lines.push_back(list_line)
						
			TYPE_DICTIONARY:
				var item_dict := Dictionary(item)
				if item_dict.empty():
					line += "%s: {}" % keys[i]
					out_lines.push_back(line)
				else:
					line += "%s:" % keys[i]
					out_lines.push_back(line)
					encode_all(out_lines, item_dict, depth_level + 1)
					
			_:
				line += "%s: %s" % [keys[i], item]
				out_lines.push_back(line)
				
		if depth_level == 0:
			out_lines.push_back("")
