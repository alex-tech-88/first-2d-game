extends Node2D

const SPEED: float = 60.0
const FALL_SPEED: float = 220.0       
const DESPAWN_TIME: float = 1.0     

var direction: int = 1
var dead: bool = false

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var slime_hit: AudioStreamPlayer2D = $Hitzone/slime_hit


func _process(delta: float) -> void:
	if dead:
		position.y += FALL_SPEED * delta # Sprite falling down
		return

	# Sprite ray casts
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

	position.x += direction * SPEED * delta


func _on_hitzone_body_entered(body: Node2D) -> void:
	if dead:
		return

	# Only if player is falling from above
	if body.is_in_group("Player") and body.velocity.y > 0.0:
		kill_by_stomp(body as CharacterBody2D)


func kill_by_stomp(player: CharacterBody2D) -> void:
	dead = true

	# Switching off killzone when hitting a sprite
	if has_node("Killzone"):
		$Killzone.monitoring = false
		
	# Switching off ray casts
	ray_cast_right.enabled = false
	ray_cast_left.enabled = false

	# Bounce
	if player.has_method("bounce"):
		player.bounce()

	# Slime being hit sound effect
	slime_hit.play()
	animated_sprite.play("slime-hit")
	
	await get_tree().create_timer(DESPAWN_TIME).timeout
	queue_free()
