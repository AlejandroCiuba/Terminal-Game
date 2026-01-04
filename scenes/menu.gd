extends Control


@export var type_delay: float = 2.0
@export var title: String = "Terminal"
@onready var title_screen: Control = %TitleScreen
@onready var options_screen: Control = %OptionsScreen
@onready var credits_screen: Control = %CreditsScreen
@onready var crt: CanvasLayer = %CRT


func _on_timeout(letter: String):
	%Title.text += letter


func _ready():
	title_screen.show()
	options_screen.hide()
	credits_screen.hide()
	%Title.text = ""

	for letter in title:
		await get_tree().create_timer(type_delay).timeout
		_on_timeout(letter)


func _on_start_pressed() -> void:
	Manager.change_scene("res://scenes/main.tscn")


func _on_title_pressed() -> void:
	title_screen.show()
	options_screen.hide()
	credits_screen.hide()


func _on_credits_pressed() -> void:
	credits_screen.show()
	options_screen.hide()
	title_screen.hide()


func _on_options_pressed() -> void:
	options_screen.show()
	title_screen.hide()
	credits_screen.hide()


func _on_terminal_effect_toggled(toggled_on: bool) -> void:
	Manager.settings["CRT"] = not toggled_on
	crt.visible = Manager.settings["CRT"]


func _on_sounds_toggled(toggled_on: bool) -> void:
	Manager.settings["MUTE"] = toggled_on
	AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), Manager.settings["MUTE"])
