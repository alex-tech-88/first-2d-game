extends CharacterBody2D

const SPEED: float = 60.0
const GRAVITY: float = 980.0
const JUMP_VELOCITY: float = -300.0
const JUMP_COOLDOWN: float = 0.8
const MAX_HP: int = 3  # Number of hits before the orc dies

var dead: bool = false
var is_attacking: bool = false
var is_hit: bool = false        # True while hit stun animation is playing
var target: Node2D = null       # Reference to the player when detected
var jump_cooldown_timer: float = 0.0
var hp: int = MAX_HP

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: Area2D = %KillZone
@onready var right_shape: CollisionShape2D = %KillZone/RightShape2D
@onready var left_shape: CollisionShape2D = %KillZone/LeftShape2D
@onready var detection_zone: Area2D = $DetectionZone  # Large zone — starts chasing
@onready var attack_zone: Area2D = $AttackZone        # Small zone — triggers melee attack
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var jump_hit: Area2D = $OrcJumpHit           # Area on top of orc's head

func _ready() -> void:
	add_to_group("Enemy")
	sword_hitbox.monitoring = false
	# Disable both sword collision shapes until an attack begins
	right_shape.disabled = true
	left_shape.disabled = true
	animated_sprite.frame_changed.connect(_on_frame_changed)
	sword_hitbox.body_entered.connect(_on_sword_hit)
	jump_hit.body_entered.connect(_on_jump_hit)

func _physics_process(delta: float) -> void:
	if dead:
		return

	# Freeze horizontal movement during hit stun, but keep gravity
	if is_hit:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		velocity.x = 0
		move_and_slide()
		return

	if jump_cooldown_timer > 0.0:
		jump_cooldown_timer -= delta

	# Always apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Poll detection zone every frame instead of relying on body_exited signals.
	# Prevents the orc from losing the player when they jump over him.
	var bodies = detection_zone.get_overlapping_bodies()
	var player_detected = false
	for body in bodies:
		if body.is_in_group("Player"):
			target = body
			player_detected = true
			break

	# Player left detection zone — return to idle
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
	# Sync active sword hitbox side with facing direction
	_update_sword_shape()

	# Use get_overlapping_bodies() so it works even if player was already inside
	var player_in_attack_zone = target in attack_zone.get_overlapping_bodies()

	if player_in_attack_zone:
		# Stop and swing
		velocity.x = 0
		if not is_attacking:
			_attack()
	else:
		# Cancel attack if player left the zone mid-swing
		if is_attacking:
			_cancel_attack()
		# Chase the player
		velocity.x = direction.x * SPEED
		animated_sprite.play("orc_walk")

	move_and_slide()

func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	jump_cooldown_timer = JUMP_COOLDOWN

# Enable collision shape only on the side the orc is facing
func _update_sword_shape() -> void:
	right_shape.set_deferred("disabled", animated_sprite.flip_h)
	left_shape.set_deferred("disabled", not animated_sprite.flip_h)

# Cleanly interrupt an ongoing attack
func _cancel_attack() -> void:
	is_attacking = false
	sword_hitbox.set_deferred("monitoring", false)
	right_shape.set_deferred("disabled", true)
	left_shape.set_deferred("disabled", true)
	# Disconnect to avoid ghost callbacks after cancellation
	if animated_sprite.animation_finished.is_connected(_on_attack_finished):
		animated_sprite.animation_finished.disconnect(_on_attack_finished)

func _on_frame_changed() -> void:
	if animated_sprite.animation == "orc_fighting":
		# Enable hitbox only on frames where the sword is visually extended
		var sword_active = animated_sprite.frame in [3, 4, 9, 10]
		sword_hitbox.set_deferred("monitoring", sword_active)
		if sword_active:
			_update_sword_shape()
		else:
			right_shape.set_deferred("disabled", true)
			left_shape.set_deferred("disabled", true)
	else:
		# Not attacking — keep everything off
		sword_hitbox.set_deferred("monitoring", false)
		right_shape.set_deferred("disabled", true)
		left_shape.set_deferred("disabled", true)

func _attack() -> void:
	if is_attacking:
		return
	is_attacking = true
	animated_sprite.play("orc_fighting")
	animated_sprite.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)

func _on_attack_finished() -> void:
	is_attacking = false
	sword_hitbox.set_deferred("monitoring", false)
	right_shape.set_deferred("disabled", true)
	left_shape.set_deferred("disabled", true)
	if target == null:
		animated_sprite.play("orc_idle")
	else:
		# Decide whether to attack again or resume chasing
		var player_in_attack_zone = target in attack_zone.get_overlapping_bodies()
		if player_in_attack_zone:
			_attack()
		else:
			animated_sprite.play("orc_walk")

func _on_sword_hit(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.die()

func _on_jump_hit(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	# Only register a stomp if the player is actually falling down onto the orc
	if body.velocity.y > 0.0:
		body.bounce()  # launch player upward immediately
		take_damage()

func take_damage() -> void:
	# Ignore hits during death or hit stun
	if dead or is_hit:
		return
	hp -= 1
	if hp <= 0:
		_die()
	else:
		# Play hit sound only if the orc survives the hit
		hit_sound.play()
		_play_hit_stun()

func _play_hit_stun() -> void:
	if is_attacking:
		_cancel_attack()
	is_hit = true
	animated_sprite.play("orc_hit")
	# Use a timer instead of animation_finished to guarantee is_hit resets
	await get_tree().create_timer(0.5).timeout
	is_hit = false

func _die() -> void:
	dead = true
	is_hit = false
	is_attacking = false
	velocity = Vector2.ZERO
	sword_hitbox.set_deferred("monitoring", false)
	right_shape.set_deferred("disabled", true)
	left_shape.set_deferred("disabled", true)
	# Disconnect attack callback so it can't fire during death sequence
	if animated_sprite.animation_finished.is_connected(_on_attack_finished):
		animated_sprite.animation_finished.disconnect(_on_attack_finished)
	# Stop all game logic for this node
	set_physics_process(false)
	# Slow down death animation to match the audio clip length (2.4s)
	animated_sprite.speed_scale = 0.33
	animated_sprite.play("orc_death")
	death_sound.play()
	await get_tree().create_timer(2.4).timeout
	queue_free()
