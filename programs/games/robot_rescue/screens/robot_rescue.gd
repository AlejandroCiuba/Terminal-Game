extends Node2D

@export var player: CharacterBody2D

@onready var hazards: Node2D = $Hazards
@onready var lasers: Node2D = $Lasers
@onready var camera: Camera2D = %PlayerCamera

func _on_body_fell(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.position = Vector2(119.0, 502.0)


func _ready() -> void:
	camera.make_current()
	for hazard in hazards.get_children():
		if hazard is Area2D:
			hazard.body_entered.connect(_on_body_fell)
	for weapon in get_tree().get_nodes_in_group("weapons"):
		weapon.shot_fired.connect(func(l: Laser): lasers.add_child(l))


func _on_player_died() -> void:
	print_debug("Game Over")
