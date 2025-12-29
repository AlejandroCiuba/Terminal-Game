extends Control

var player_left: bool = false
@export_multiline var text: String = ""
@export var speed: float = 0.1
@export var trigger: Area2D = null
@onready var text_box: RichTextLabel = %Text


func _ready() -> void:
	hide()
	if trigger != null:
		trigger.body_entered.connect(display_text)
		trigger.body_exited.connect(clear)
	else:
		display_text(null)


func display_text(_body: Node2D) -> void:
	player_left = false
	show()
	text_box.text = ""
	for c in text:
		if player_left:
			text_box.text = ""
			return
		text_box.text += c
		await get_tree().create_timer(speed).timeout
		
		
func clear(_body: Node2D) -> void:
	text_box.text = ""
	player_left = true
	hide()
