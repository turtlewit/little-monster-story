#include <ResourceLoader.hpp>
#include <Script.hpp>
#include <Texture.hpp>

#include "plugin.hpp"

using namespace godot;

void Plugin::_register_methods()
{
	register_method("_enter_tree", &Plugin::_enter_tree);
	register_method("_exit_tree", &Plugin::_exit_tree);
}

void Plugin::_init()
{
}

void Plugin::_enter_tree()
{
	add_custom_type("PropArea", "Spatial", ResourceLoader::get_singleton()->load("res://addons/prop_area/prop_area.gdns"), nullptr);
}

void Plugin::_exit_tree()
{
	remove_custom_type("PropArea");
}
