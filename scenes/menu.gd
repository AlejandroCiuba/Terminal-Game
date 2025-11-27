extends Control


@export var type_delay: float = 2.0
@export var title: String = "Terminal"


func _on_timeout(letter: String):
	%Title.text += letter


func _ready():
	%Title.text = ""

	for letter in title:
		await get_tree().create_timer(type_delay).timeout
		_on_timeout(letter)


func _on_start_pressed() -> void:
	Manager.change_scene("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
