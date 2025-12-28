## Hurtbox and health are bundled for this
extends Area2D

signal no_health

@export var health: int = 5:
	set(value):
		health = value
		if health <= 0:
			no_health.emit()


func _on_area_entered(area: Area2D) -> void:
	if area is Laser:
		health -= area.damage
	else:
		health -= 1
