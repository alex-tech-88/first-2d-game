extends Node2D

const SPEED = 60
const FALL_SPEED = 220       
const DESPAWN_TIME = 1.0     

var direction = 1
var dead := false

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D
@onready var slime_hit = $Hitzone/slime_hit


func _process(delta):
	if dead:
		position.y += FALL_SPEED * delta # Sprite falling down
		return

	# Srite ray casts
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false

	position.x += direction * SPEED * delta


func _on_hitzone_body_entered(body):
	if dead:
		return

	# Only if player is falling from above
	if body.is_in_group("Player") and body.velocity.y > 0:
		kill_by_stomp(body)


func kill_by_stomp(player):
	dead = true

	# Switching off killzone when hitting a sprite
	if has_node("Killzone"):
		$Killzone.monitoring = false
		
	# Switching off ray casts
	if has_node("RayCastRight"):
		$RayCastRight.enabled = false

	if has_node("RayCastLeft"):
		$RayCastLeft.enabled = false

	# Bounce
	if player.has_method("bounce"):
		player.bounce()

	# Slime being hit sound effect
	slime_hit.play()
	animated_sprite.play("slime-hit")
	
	await get_tree().create_timer(DESPAWN_TIME).timeout
	queue_free()
