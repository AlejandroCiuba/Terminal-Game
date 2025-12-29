extends Control


@export var type_delay: float = 2.0
@export var title: String = "Terminal"
@onready var title_screen: Control = %TitleScreen
@onready var credits_screen: Control = %CreditsScreen


func _on_timeout(letter: String):
	%Title.text += letter


func _ready():
	title_screen.show()
	credits_screen.hide()
	%Title.text = ""

	for letter in title:
		await get_tree().create_timer(type_delay).timeout
		_on_timeout(letter)


func _on_start_pressed() -> void:
	Manager.change_scene("res://scenes/main.tscn")


func _on_title_pressed() -> void:
	title_screen.show()
	credits_screen.hide()


func _on_credits_pressed() -> void:
	credits_screen.show()
	title_screen.hide()
