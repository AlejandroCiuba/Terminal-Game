extends Node

var settings: Dictionary = {
	"CRT": true,
	"MUTE": false,
}

func change_scene(file: String) -> void:
	get_tree().change_scene_to_file(file)
