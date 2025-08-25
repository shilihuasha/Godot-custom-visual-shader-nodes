@tool
extends EditorPlugin



var loaded_scripts: Array = []

func _enter_tree() -> void:
	var folder := "res://addons/custom_visual_shader_node/visual_shader_nodes/"
	var dir := DirAccess.open(folder)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".gd"):
				var path = folder + file_name
				var script = load(path)
				if script:
					loaded_scripts.append(script)
					print("Loaded VisualShaderNode script:", path)
			file_name = dir.get_next()
		dir.list_dir_end()

func _exit_tree() -> void:
	loaded_scripts.clear()
	print("Custom shader nodes unloaded")
