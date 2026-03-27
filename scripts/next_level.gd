extends Area2D

# Base path for level files (e.g. res://scenes/levels/level_1.tscn)
const FILE_BEGIN = "res://scenes/levels/level_"

@onready var sprite: Sprite2D = $Sprite2D
@onready var game_manager: Node = %GameManager  # Must be marked as unique name in the scene
@onready var portal_sound: AudioStreamPlayer2D = $PortalSound

# Stores the original scale of the portal sprite
var base_scale: Vector2 = Vector2.ZERO
# Prevents _on_body_entered from firing twice while transitioning
var is_transitioning: bool = false


func _ready() -> void:
	# Save the initial scale before any animation modifies it
	base_scale = sprite.scale


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	var locked: bool = not game_manager.has_enough_coins()

	# Reduce pulse intensity when locked
	var pulse_strength_x: float = 0.01 if locked else 0.04
	var pulse_strength_y: float = 0.015 if locked else 0.06

	# Slightly different frequencies on X and Y for an organic breathing feel
	var pulse_x: float = 1.0 + sin(t * 2.4) * pulse_strength_x
	var pulse_y: float = 1.0 + sin(t * 2.4 + 0.5) * pulse_strength_y
	sprite.scale = Vector2(base_scale.x * pulse_x, base_scale.y * pulse_y)

	# Dim the portal when locked, restore full opacity when unlocked
	sprite.modulate.a = _get_target_alpha()


# Returns the target alpha based on whether the portal is unlocked
func _get_target_alpha() -> float:
	var t: float = Time.get_ticks_msec() / 1000.0
	if game_manager.has_enough_coins():
		# Subtle flicker when the portal is open
		return 0.92 + sin(t * 3.2) * 0.06
	else:
		# Very dim and almost static when locked
		return 0.25 + sin(t * 0.8) * 0.03


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if not game_manager.has_enough_coins():
		return
	if is_transitioning:
		return
	is_transitioning = true

	portal_sound.play()
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.play_portal_flash()

	var current_scene_file: String = get_tree().current_scene.scene_file_path
	var current_level: int = current_scene_file.get_basename().get_file().to_int()

	# Shorter wait before credits, full sound for level transitions
	var wait_time: float = 0.4 if current_level >= 2 else 1.2
	await get_tree().create_timer(wait_time).timeout

	if current_level >= 2:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/credits.tscn")
	else:
		var next_level_path: String = FILE_BEGIN + str(current_level + 1) + ".tscn"
		get_tree().call_deferred("change_scene_to_file", next_level_path)
