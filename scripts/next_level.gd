extends Area2D

# Base path for level files (e.g. res://levels/level_1.tscn)
const FILE_BEGIN = "res://scenes/levels/level_"

@onready var sprite: Sprite2D = $Sprite2D

# Stores the original scale of the portal sprite
var base_scale: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Save the initial scale before any animation
	base_scale = sprite.scale


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0

	# Slightly different frequencies on X and Y for organic feel
	var pulse_x: float = 1.0 + sin(t * 2.4) * 0.04
	var pulse_y: float = 1.0 + sin(t * 2.4 + 0.5) * 0.06
	sprite.scale = Vector2(base_scale.x * pulse_x, base_scale.y * pulse_y)

	# Subtle alpha flicker
	var alpha: float = 0.92 + sin(t * 3.2) * 0.06
	sprite.modulate.a = alpha


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		# Extract current level number from scene file path and increment it
		var current_scene_file: String = get_tree().current_scene.scene_file_path
		var next_level_number: int = current_scene_file.get_basename().get_file().to_int() + 1
		var next_level_path: String = FILE_BEGIN + str(next_level_number) + ".tscn"
		get_tree().call_deferred("change_scene_to_file", next_level_path)
