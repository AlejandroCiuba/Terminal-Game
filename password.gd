extends Program

signal password(pwd: String)


func _process(delta: float) -> void:

	if Input.is_action_just_pressed("new_line"):
		password.emit(%Password.text)
		exited.emit()
		self.free()
