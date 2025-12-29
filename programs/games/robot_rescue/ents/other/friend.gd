extends CharacterBody2D

const gravity: float = 50.0


func _ready() -> void:
	$AnimatedSprite2D.play("idle")


func _physics_process(_delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity
		
	move_and_slide()
