extends InLineProgram

signal password(pwd: String)


func _ready() -> void:
	%Password.grab_focus()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("new_line"):
		password.emit(%Password.text)
		exited.emit()
