#pragma once

#include <Godot.hpp>
#include <EditorPlugin.hpp>

class Plugin : public godot::EditorPlugin {
	GODOT_CLASS(Plugin, godot::EditorPlugin)

public:
	static void _register_methods();

	void _init();
	void _enter_tree();
	void _exit_tree();
};
