# Settings System
#
# Responsible for saving, loading, and setting settings.
#
# To respond to a particular setting being set, subscribe to the 
# setting_modified signal. If this is done after settings have been loaded
# (which is likely), you should also make sure to apply the settings when
# the node are system is initializing.
#
# Saving and loading is done with save_settings() and load_settings(). To
# modify a setting, use set_setting. Do not modify the settings property directly.
extends Node


signal setting_modified(section, setting, value)

# DO NOT MODIFY DIRECTLY
# call set_setting() instead
var settings := {
	"gameplay": {
		"disable_active_camera": false,
	},
	"volume": {
		"master": 1.0,
		"music": 1.0,
		"sfx": 1.0,
		"text": 1.0,
		"ambiance": 1.0,
	},
	"video": {
		"fxaa": true,
		"shadow_quality": 3,
		"grass_density": 0,
		"fullscreen": false,
		"msaa": 1,
	},
	"controls": {
		"gamepad_index": 0,
		"disable_mouse_grab": false,
		"camera_sensitivity_mouse_x": 2.0,
		"camera_sensitivity_mouse_y": 2.0,
		"camera_sensitivity_joystick_x": 2.0,
		"camera_sensitivity_joystick_y": 2.0,
	},
	"physics": {
		"fps": 60.0,
	},
}


# Call this to set a particular setting. This way, any system
# that relies on this setting can be notified when it changes.
func set_setting(section: String, setting: String, value) -> void:
	if not settings.has(section) or not settings[section].has(setting):
		push_error("Unrecognized setting: %s:%s" % [section, setting])
	settings[section][setting] = value
	emit_signal("setting_modified", section, setting, value)


# Loads the settings and calls set_setting() for each loaded setting.
func load_settings() -> void:
	var settings_file := ConfigFile.new()
	if settings_file.load("user://settings.cfg") != OK:
		save_settings()
		return
	
	for section in settings_file.get_sections():
		for key in settings_file.get_section_keys(section):
			if settings.has(section) and settings[section].has(key):
				set_setting(section, key, settings_file.get_value(section, key))
			else:
				push_warning("Encountered unrecognised setting in settings file: %s:%s" % [section, key])
	var needs_save := false
	for section in settings:
		for key in settings[section]:
			if not settings_file.has_section_key(section, key):
				needs_save = true
				set_setting(section, key, settings[section][key])


# Saves the settings currently in settings
func save_settings() -> void:
	var settings_file := ConfigFile.new()
	for section in settings.keys():
		for setting in settings[section].keys():
			settings_file.set_value(section, setting, settings[section][setting])
	var result = settings_file.save("user://settings.cfg")
	if result != OK:
		push_error("Could not save config file! Error: %d" % result)


func _ready() -> void:
	connect("setting_modified", self, "_on_setting_modified")
	load_settings()


func _on_setting_modified(section: String, setting: String, value) -> void:
	match section:
		"volume":
			match setting:
				"master":
					AudioServer.set_bus_volume_db(0, linear2db(value))
				"music":
					AudioServer.set_bus_volume_db(1, linear2db(value))
				"sfx":
					AudioServer.set_bus_volume_db(2, linear2db(value))
				"text":
					AudioServer.set_bus_volume_db(3, linear2db(value))
				"ambiance":
					AudioServer.set_bus_volume_db(5, linear2db(value))
		"physics":
			match setting:
				"fps":
					Engine.iterations_per_second = value
		"video":
			match setting:
				"shadow_quality":
					var v: int = 4096 * (value + 1)
					if ProjectSettings.get_setting("rendering/quality/directional_shadow/size") != v:
						var ps := ConfigFile.new()
						ps.set_value("rendering", "quality/directional_shadow/size", v)
						ps.save("user://override.cfg")
				"msaa":
					match value:
						0:
							get_tree().root.set_msaa(Viewport.MSAA_DISABLED)
						1:
							get_tree().root.set_msaa(Viewport.MSAA_2X)
						2:
							get_tree().root.set_msaa(Viewport.MSAA_4X)
						3:
							get_tree().root.set_msaa(Viewport.MSAA_8X)
				"fullscreen":
					OS.window_fullscreen = value
