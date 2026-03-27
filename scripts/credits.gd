extends Control

# Seconds each label takes to fade in
const FADE_DURATION: float = 1.2
# Pause between each label appearing
const LABEL_DELAY: float = 0.8

@onready var labels: Array = [
	$CanvasLayer/VBoxContainer/LabelComingSoon,
	$CanvasLayer/VBoxContainer/LabelThankYou,
	$CanvasLayer/VBoxContainer/LabelCreatedBy
]


func _ready() -> void:
	# Hide all labels initially
	for label in labels:
		label.modulate.a = 0.0
	_play_credits()


func _play_credits() -> void:
	# Fade in each label one by one
	for label in labels:
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1.0, FADE_DURATION)
		await tween.finished
		await get_tree().create_timer(LABEL_DELAY).timeout

func _input(event: InputEvent) -> void:
	# Skip credits and return to main menu
	if event.is_action_pressed("pause"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
