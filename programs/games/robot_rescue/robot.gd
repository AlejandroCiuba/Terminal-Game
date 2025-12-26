extends CharacterBody2D
# I checked https://indiegameacademy.com/how-to-make-a-smooth-movement-system-for-a-2d-platformer-in-godot/ 
# to see if animations could be played in the _physics_process

var coyote_timer: float = 0.0
const COYOTE_THRESHOLD = 0.1

@export var _speed: float = 400.0
@export var _jump_force: float = -500.0
@export var _gravity: float = 100.0

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D


func anim_handler() -> void:
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


func _physics_process(delta: float) -> void:
	
	if is_on_floor():
		coyote_timer = 0.0
	else:
		velocity.y += _gravity
		coyote_timer += delta
		
	if Input.is_action_just_pressed("jump") and (is_on_floor() or coyote_timer < COYOTE_THRESHOLD):
		velocity.y = _jump_force
		coyote_timer = COYOTE_THRESHOLD
	
	var dir: float = Input.get_axis("left", "right")
	velocity.x = dir * _speed
	
	move_and_slide()
	anim_handler()
