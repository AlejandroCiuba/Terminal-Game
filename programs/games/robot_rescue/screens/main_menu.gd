extends Program

var game: PackedScene = preload("res://programs/games/robot_rescue/screens/robot_rescue.tscn")
@onready var game_point: Node2D = %Game
@onready var menu: Control = %Menu


func _on_play_pressed() -> void:
	var g: Node2D = game.instantiate()
	game_point.add_child(g)
	menu.hide()


func _on_quit_pressed() -> void:
	exited.emit()
