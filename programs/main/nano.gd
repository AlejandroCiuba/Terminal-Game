extends Program

var file: Directory.File


func _ready() -> void:

	%Filename.text = file.itemname
	%FileInfo.text = "%d Chars" % len(%Editor.text)
	%Editor.text = file.contents
	entered.emit()


func _process(_delta: float) -> void:

	if Input.is_key_pressed(KEY_CTRL):
		%Editor.release_focus()
	elif not Input.is_key_pressed(KEY_CTRL):
		%Editor.grab_focus()

	if Input.is_action_just_pressed("quit"):
		exited.emit()

	elif Input.is_action_just_pressed("write_out"):
		file.contents = %Editor.text


func _on_editor_text_changed() -> void:
	%FileInfo.text = "%d Chars" % len(%Editor.text)
