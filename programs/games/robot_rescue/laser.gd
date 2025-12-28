class_name Laser
extends Area2D

var direction: Vector2 = Vector2.RIGHT
@export var damage: int = 1
@export var _speed: float = 30.0
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	if is_equal_approx(direction.x, -1):
		_anim.flip_h = true
	if is_equal_approx(direction.y, 1):
		_anim.flip_v = true
	_anim.play("fire")


func _physics_process(delta: float) -> void:
	global_position += _speed * direction * delta


func _on_hit(_body: Node2D) -> void:
	print_debug("HIT ", _body.name)
	set_physics_process(false)
	_anim.play("hit")
	await _anim.animation_finished
	queue_free()
