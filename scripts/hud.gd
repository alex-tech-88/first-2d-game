extends Control
class_name HUD

@export var coin_label: Label
@onready var screen_flash: ColorRect = $ScreenFlash


func _ready() -> void:
	add_to_group("hud")
	# Make sure flash is invisible on scene start
	screen_flash.modulate.a = 0.0


func update_coin_label(number: int) -> void:
	coin_label.text = "x" + str(number) + "/6"


# Plays a white flash — call before scene transition
func play_portal_flash() -> void:
	var tween = create_tween()
	# Slow fade in across most of the sound duration
	tween.tween_property(screen_flash, "modulate:a", 1.0, 0.9)
	# Hold at peak right when scene switches
	tween.tween_interval(0.1)
	# Fade out on the new scene
	tween.tween_property(screen_flash, "modulate:a", 0.0, 0.4)
