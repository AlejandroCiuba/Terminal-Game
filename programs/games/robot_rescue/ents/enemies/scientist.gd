extends CharacterBody2D


var _current_time: float = 0.0
var _player_spotted: bool = false
var _dead: bool = false
var _player: Node2D = null
@export var health: int = 5
@export var _start_direction: float = 1.0
@export var _speed: float = 300.0
@export var _jump: float = -400.0
@export var _gravity: float = 50.0
@export var _turn_timer: float = 5.0
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _weapon: Weapon = $Weapon


func _move(delta: float) -> void:
	if is_on_wall() and is_on_floor():
		velocity.y = _jump
	velocity.x = _start_direction * _speed
	_current_time += delta
	if _current_time >= _turn_timer:
		_start_direction *= -1
		_current_time = 0.0
	_anim_move()


func _shoot() -> void:
	if _player == null:
		return
	velocity.x = 0.0
	if _player.global_position.x - global_position.x < 0.0:
		_anim.flip_h = true
		_weapon.fire(Vector2.LEFT)
		_anim.play("shoot")
	elif _player.global_position.x - global_position.x > 0.0:
		_anim.flip_h = false
		_weapon.fire(Vector2.RIGHT)
		_anim.play("shoot")
	else:
		_player_spotted = false


func _anim_move() -> void:
	if _start_direction < 0.0:
		_anim.flip_h = true
		_anim.play("walk")
	elif _start_direction > 0.0:
		_anim.flip_h = false
		_anim.play("walk")


func _physics_process(delta: float) -> void:
	move_and_slide()
	if _dead:
		return
	if not _player_spotted:
		_move(delta)
	if _player_spotted:
		_shoot()
	if not is_on_floor():
		velocity.y += _gravity


func _on_alert(body: Node2D) -> void:
	print_debug("Player Detected")
	_player = body
	_player_spotted = true


func _on_alert_exited(_body: Node2D) -> void:
	print_debug("Player Left")
	_player = null
	_player_spotted = false


func _on_no_health() -> void:
	print_debug("Scientist Eliminated")
	velocity.x = 0.0
	_anim.play("die")
	_dead = true
	await _anim.animation_finished
	hide()
	queue_free()
