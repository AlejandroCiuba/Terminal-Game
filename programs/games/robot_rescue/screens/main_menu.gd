extends Program

var game: PackedScene = preload("res://programs/games/robot_rescue/screens/robot_rescue.tscn")
var curr_game: Node2D = null
@onready var game_point: Node2D = %Game
@onready var menu: Control = %Menu


func _on_play_pressed() -> void:
	if curr_game != null:
		curr_game.game_over.exit_in_game.disconnect(_on_quit_pressed)
		curr_game.game_over.retry_in_game.disconnect(_on_play_pressed)
		var del_game: Node2D = curr_game  # Prevents race condition
		(func (): del_game.queue_free()).call_deferred()
	var g: Node2D = game.instantiate()
	game_point.add_child(g)
	g.game_over.exit_in_game.connect(_on_quit_pressed)
	g.game_over.retry_in_game.connect(_on_play_pressed)
	curr_game = g
	menu.hide()


func _on_quit_pressed() -> void:
	exited.emit()
