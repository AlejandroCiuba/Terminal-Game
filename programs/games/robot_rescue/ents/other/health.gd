extends Control

@export var health: int = 5
@onready var _container: HBoxContainer = $HBoxContainer
@onready var _heart: TextureRect = $HBoxContainer/Heart


func _ready() -> void:
	if self not in get_tree().root.get_children():
		return
	for i in range(health - 1):
		var h: TextureRect = _heart.duplicate()
		_container.add_child(h)


func set_health(h: int) -> void:
	health = h
	for i in range(health - 1):
		var hp: TextureRect = _heart.duplicate()
		_container.add_child(hp)


func remove_health() -> void:
	_container.get_child(health - 1).queue_free()
	health -= 1
