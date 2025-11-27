extends Program

var file: Directory.File


func _ready() -> void:
	%Editor.text = file.contents


func _process(delta: float) -> void:

	if Input.is_action_just_pressed("quit"):
		exited.emit()
		self.free()

	elif Input.is_action_just_pressed("write_out"):
		file.contents = %Editor.text
