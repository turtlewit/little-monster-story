#pragma once

#include <Godot.hpp>
#include <Spatial.hpp>
#include <Shape.hpp>
#include <PackedScene.hpp>
#include <MultiMesh.hpp>
#include <MultiMeshInstance.hpp>
#include <Transform.hpp>
#include <Path.hpp>
#include <Curve2D.hpp>
#include <RandomNumberGenerator.hpp>
#include <Mesh.hpp>

class PropArea : public godot::Spatial {
	GODOT_CLASS(PropArea, godot::Spatial)

public:
	static void _register_methods();

	void _init();
	void _notification(int what);
	void _ready();
	void _process(float delta);
	godot::String _get_configuration_warning();

	void _on_path_curve_changed();

	int64_t get_number_of_instances() { return number_of_instances; }
	void set_number_of_instances(int64_t value)
	{
		if (multi_mesh_instance->get_multimesh()->get_instance_count() != value) {
			number_of_instances = value;
			refresh();
		} else {
			number_of_instances = value;
		}
	}

	int64_t get_layers()
	{
		return multi_mesh_instance->get_layer_mask();
	}

	void set_layers(int64_t layers)
	{
		multi_mesh_instance->set_layer_mask(layers);
	}

	godot::Ref<godot::Mesh> get_mesh() 
	{ 
		return multi_mesh_instance->get_multimesh()->get_mesh(); 
	}
	void set_mesh(godot::Ref<godot::Mesh> mesh) 
	{ 
		multi_mesh_instance->get_multimesh()->set_mesh(mesh); 
	}

	~PropArea() {}

private:
	void refresh();
	void find_path();
	void update_curve();
	godot::Spatial* get_prefab_root();
	void clear_prefabs();

	godot::MultiMeshInstance* multi_mesh_instance;
	godot::Ref<godot::RandomNumberGenerator> rng;
	godot::Ref<godot::PackedScene> prefab;
	godot::Vector3 base_position;
	godot::Vector3 base_rotation;
	godot::Vector3 base_scale;
	int64_t number_of_instances;
	bool randomize_rotation;
	float min_distance;
	int64_t collision_mask;
	bool in_tree;

	godot::Path* path;
	godot::Ref<godot::Curve2D> curve2d;
};
