extends CharacterBody2D

const SPEED: float = 60.0
const GRAVITY: float = 980.0
var dead: bool = false
var is_attacking: bool = false
var target: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: Area2D = %KillZone
@onready var right_shape: CollisionShape2D = %KillZone/RightShape2D
@onready var left_shape: CollisionShape2D = %KillZone/LeftShape2D
@onready var detection_zone: Area2D = $DetectionZone
@onready var attack_zone: Area2D = $AttackZone

func _ready() -> void:
	add_to_group("Enemy")
	sword_hitbox.monitoring = false
	# Disable both sword shapes until an attack begins
	right_shape.disabled = true
	left_shape.disabled = true
	animated_sprite.frame_changed.connect(_on_frame_changed)
	sword_hitbox.body_entered.connect(_on_sword_hit)

func _physics_process(delta: float) -> void:
	if dead:
		return

	# Always apply gravity so the orc doesn't float
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Poll the detection zone every frame 
	var bodies = detection_zone.get_overlapping_bodies()
	var player_detected = false
	for body in bodies:
		if body.is_in_group("Player"):
			target = body
			player_detected = true
			break

	# Player left the detection zone — reset
	if not player_detected:
		target = null
		if not is_attacking:
			velocity.x = 0
			animated_sprite.play("orc_idle")
		move_and_slide()
		return

	# Face the player every frame
	var direction = global_position.direction_to(target.global_position)
	animated_sprite.flip_h = direction.x < 0
	# Keep the correct sword hitbox side active
	_update_sword_shape()

	# Check if player is close enough to attack
	var player_in_attack_zone = target in attack_zone.get_overlapping_bodies()

	if player_in_attack_zone:
		# Stop and attack
		velocity.x = 0
		if not is_attacking:
			_attack()
	else:
		# If player left attack zone mid-attack — cancel and chase
		if is_attacking:
			_cancel_attack()
		velocity.x = direction.x * SPEED
		animated_sprite.play("orc_walk")

	move_and_slide()

# Enable the collision shape on the correct side based on facing direction
func _update_sword_shape() -> void:
	right_shape.disabled = animated_sprite.flip_h    # facing left → disable right
	left_shape.disabled = not animated_sprite.flip_h  # facing right → disable left

func _on_frame_changed() -> void:
	if animated_sprite.animation == "orc_fighting":
		# Only activate the hitbox on frames where the sword is visually extended
		var sword_active = animated_sprite.frame in [3, 4, 9, 10]
		sword_hitbox.monitoring = sword_active
		if sword_active:
			# Sync the active shape with current facing direction
			_update_sword_shape()
		else:
			# Sword not extended — disable both shapes
			right_shape.disabled = true
			left_shape.disabled = true
	else:
		# Not in attack animation — disable everything
		sword_hitbox.monitoring = false
		right_shape.disabled = true
		left_shape.disabled = true

func _attack() -> void:
	if is_attacking:
		return
	is_attacking = true
	animated_sprite.play("orc_fighting")
	animated_sprite.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _on_attack_finished() -> void:
	is_attacking = false
	sword_hitbox.monitoring = false
	right_shape.disabled = true
	left_shape.disabled = true
	# If player is gone, go back to idle
	if target == null:
		animated_sprite.play("orc_idle")
	else:
		# Check immediately after attack ends what to do next
		var player_in_attack_zone = target in attack_zone.get_overlapping_bodies()
		if player_in_attack_zone:
			# Player still in range — attack again
			_attack()
		else:
			# Player moved away — chase
			animated_sprite.play("orc_walk")
			
func _on_sword_hit(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.die()

func take_damage() -> void:
	if dead:
		return
	dead = true
	velocity.x = 0
	sword_hitbox.monitoring = false
	right_shape.disabled = true
	left_shape.disabled = true
	animated_sprite.play("orc_death")
	await get_tree().create_timer(1.0).timeout
	queue_free()
	
# Interrupt the current attack cleanly
func _cancel_attack() -> void:
	is_attacking = false
	sword_hitbox.monitoring = false
	right_shape.disabled = true
	left_shape.disabled = true
	# Disconnect the finished signal to avoid ghost callbacks
	if animated_sprite.animation_finished.is_connected(_on_attack_finished):
		animated_sprite.animation_finished.disconnect(_on_attack_finished)
