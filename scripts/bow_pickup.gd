extends Area2D

# --- Animation constants ---
const HOVER_AMPLITUDE: float = 6.0   # Pixels up and down
const HOVER_SPEED: float = 2.0       # Oscillations per second
const ROTATE_SPEED: float = 0.6      # Radians per second
const PULSE_SCALE: float = 0.06      # Max scale change for attention pulse

@onready var pickup_sound: AudioStreamPlayer2D = $PickupSound

# Stored origin so hover is relative to placement in the level
var origin_y: float = 0.0


func _ready() -> void:
	origin_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0

	# Hovering up and down
	position.y = origin_y + sin(t * HOVER_SPEED) * HOVER_AMPLITUDE

	# Slow rotation to draw attention
	rotation += ROTATE_SPEED * delta

	# Gentle scale pulse
	var pulse: float = 1.0 + sin(t * 3.0) * PULSE_SCALE
	scale = Vector2(pulse, pulse)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	body.pickup_bow()

	# Stop hovering and hide sprite immediately
	set_process(false)
	$Sprite2D.visible = false

	# Play sound and wait for it to finish before removing the node
	pickup_sound.play()
	await pickup_sound.finished
	queue_free()
