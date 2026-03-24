extends Node2D

# --- Movement constants ---
const SPEED: float = 60.0
const FALL_SPEED: float = 220.0  # Downward speed after death (falls through the floor)
const DESPAWN_TIME: float = 1.0  # Seconds before the node is removed after death

var direction: int = 1   # 1 = right, -1 = left
var dead: bool = false

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slime_hit: AudioStreamPlayer2D = $Hitzone/slime_hit


func _process(delta: float) -> void:
	if dead:
		# Fall through the floor after death
		position.y += FALL_SPEED * delta
		return

	# Reverse direction when hitting a wall
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

	position.x += direction * SPEED * delta


# --- Damage & death ---

func _on_hitzone_body_entered(body: Node2D) -> void:
	if dead:
		return
	# Only count as a stomp if the player is actually falling downward
	if body.is_in_group("Player") and body.velocity.y > 0.0:
		take_damage(body as CharacterBody2D)


# Accepts an optional player reference:
# — stomp: pass the player node so bounce() is called
# — arrow hit: call without arguments
func take_damage(player: Node2D = null) -> void:
	if dead:
		return
	dead = true
	if player and player.has_method("bounce"):
		player.bounce()  # Launch the player upward immediately
	_cleanup_and_die()


func _cleanup_and_die() -> void:
	if has_node("Killzone"):
		$Killzone.monitoring = false
	# Disable raycasts so direction logic doesn't run during death
	ray_cast_right.enabled = false
	ray_cast_left.enabled = false
	slime_hit.play()
	animated_sprite.play("slime-hit")
	await get_tree().create_timer(DESPAWN_TIME).timeout
	queue_free()
