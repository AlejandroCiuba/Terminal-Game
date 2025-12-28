extends Control

signal retry_in_game
signal exited_in_game

func _ready() -> void:
	hide()


func _on_retry_pressed() -> void:
	retry_in_game.emit()


func _on_quit_pressed() -> void:
	exited_in_game.emit()
