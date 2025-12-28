extends CharacterBody2D
# I checked https://indiegameacademy.com/how-to-make-a-smooth-movement-system-for-a-2d-platformer-in-godot/ 
# to see if animations could be played in the _physics_process

signal player_died

var disable_movement: bool = false
var coyote_timer: float = 0.0
const COYOTE_THRESHOLD = 0.1

@export var _speed: float = 400.0
@export var _jump_force: float = -500.0
@export var _gravity: float = 100.0
@onready var _weapon: Weapon = %Weapon
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _weapon_flip: float = %Weapon.position.x * -1


func _anim_handler() -> void:
	if is_on_floor():
		if velocity.x < 0.0:
			_anim.flip_h = true
			_anim.play("walk")
		elif velocity.x > 0.0:
			_anim.flip_h = false
			_anim.play("walk")
		elif is_zero_approx(velocity.x):
			_anim.play("idle")
	else:
		if velocity.y < 0.0:
			_anim.play("jump")
		else:
			_anim.play("fall")


func _process(_delta: float) -> void:
	_anim_handler()

func _physics_process(delta: float) -> void:
	
	if is_on_floor():
		coyote_timer = 0.0
	else:
		velocity.y += _gravity
		coyote_timer += delta
		
	if not disable_movement and Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_timer < COYOTE_THRESHOLD):
		velocity.y = _jump_force
		coyote_timer = COYOTE_THRESHOLD
	
	if not disable_movement:
		var dir: float = Input.get_axis("left", "right")
		velocity.x = dir * _speed
	
	move_and_slide()
	
	if _anim.flip_h:
		_weapon.position.x = _weapon_flip
	else:
		_weapon.position.x = _weapon_flip * -1
	
	if not disable_movement and is_on_floor() and Input.is_action_just_pressed("shoot"):
		_weapon.fire(Vector2(-1 if _anim.flip_h else 1, 0.0))


func _on_no_health() -> void:
	if disable_movement:  # Check to avoid repeating animation
		return
	print_debug("Game Over")
	set_process(false)
	disable_movement = true
	velocity.x = 0.0
	_anim.play("die")
	await _anim.animation_finished
	player_died.emit()
