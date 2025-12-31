extends CanvasLayer

@export var time: float = 0.1
@export var pause: float = 1.0
@onready var title_button: Button = %Title
@onready var music: AudioStreamPlayer = %Music
@onready var thank_you: RichTextLabel = %ThankYou
@onready var appear_text: RichTextLabel = %AppearText


func display_text(label: RichTextLabel, text: String) -> void:
	if not label.text.is_empty():
		label.text = ""
	for c in text:
		label.text += c
		await get_tree().create_timer(time).timeout


func _ready() -> void:
	title_button.hide()
	await display_text(thank_you, "Thank you...")
	await get_tree().create_timer(pause).timeout
	await display_text(appear_text, "I really mean it.")
	await get_tree().create_timer(pause).timeout
	music.play()
	title_button.show()


func _on_title_pressed() -> void:
	Manager.change_scene("res://scenes/menu.tscn")
