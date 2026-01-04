extends Control

@onready var crt: CanvasLayer = %CRT

func _ready() -> void:
	crt.visible = Manager.settings["CRT"]
