extends Node2D

@export var player: CharacterBody2D

@onready var hazards: Node2D = $Hazards


func _on_body_fell(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.position = Vector2(119.0, 502.0)


func _ready() -> void:
	for hazard in hazards.get_children():
		if hazard is Area2D:
			hazard.body_entered.connect(_on_body_fell)
