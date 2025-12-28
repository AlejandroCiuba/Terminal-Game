class_name Weapon
extends Node2D

signal shot_fired(laser: Laser)

var _time_since_shot: float = 0.0
var _can_shoot: bool = true
@export var _laser: PackedScene = preload("res://programs/games/robot_rescue/laser.tscn")
@export var _laser_data: LaserData
@export var _cool_down: float = 1.0


func fire(direction: Vector2) -> void:
	if _can_shoot:
		_can_shoot = false
		var l: Laser = _laser.instantiate() as Laser
		l.direction = direction
		l.global_position = global_position
		l._speed = _laser_data.speed
		l.damage = _laser_data.damage
		l.collision_mask = _laser_data.laser_collision_mask
		shot_fired.emit(l)
	
	
func _physics_process(delta: float) -> void:
	if not _can_shoot:
		_time_since_shot += delta
		if _time_since_shot >= _cool_down:
			_can_shoot = true
			_time_since_shot = 0.0
