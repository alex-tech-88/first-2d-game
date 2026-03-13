extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var base_scale: Vector2 = Vector2.ZERO

# Portal animation setup
func _ready() -> void:
	base_scale = sprite.scale

# Portal pulse animation
func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0

	var pulse_x: float = 1.0 + sin(t * 2.4) * 0.04
	var pulse_y: float = 1.0 + sin(t * 2.4 + 0.5) * 0.06
	sprite.scale = Vector2(base_scale.x * pulse_x, base_scale.y * pulse_y)

	var alpha: float = 0.92 + sin(t * 3.2) * 0.06
	sprite.modulate.a = alpha


# Trigger next level
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("next level coming soon.....")
