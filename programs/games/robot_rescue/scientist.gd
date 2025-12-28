extends CharacterBody2D


var _current_time: float = 0.0
@export var _start_direction: float = 1.0
@export var _speed: float = 300.0
@export var _jump: float = -400.0
@export var _gravity: float = 50.0
@export var _turn_timer: float = 5.0
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D


func _anim_handler() -> void:
	if _start_direction < 0.0:
		_anim.flip_h = true
		_anim.play("walk")
	elif _start_direction > 0.0:
		_anim.flip_h = false
		_anim.play("walk")


func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity.y += _gravity
		
	if is_on_wall() and is_on_floor():
		velocity.y = _jump

	velocity.x = _start_direction * _speed

	_current_time += delta
	if _current_time >= _turn_timer:
		_start_direction *= -1
		_current_time = 0.0

	move_and_slide()
	_anim_handler()


func _on_alert(_body: Node2D) -> void:
	print_debug("Player Detected")
