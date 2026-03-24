extends CharacterBody2D

# --- Movement & combat constants ---
const SPEED: float = 60.0
const GRAVITY: float = 980.0
const JUMP_VELOCITY: float = -300.0
const JUMP_COOLDOWN: float = 0.8
const MAX_HP: int = 3

# --- Timing constants ---
const DEATH_ANIM_SPEED: float = 0.53  # Slowed playback to match death audio length
const DEATH_DURATION: float = 2.4     # Seconds to wait before removing the node
const HIT_STUN_DURATION: float = 0.5  # Seconds the orc is frozen after taking a hit

# --- Animation frames where the sword hitbox should be active ---
const SWORD_ACTIVE_FRAMES: Array = [3, 4, 9, 10]

var dead: bool = false
var is_attacking: bool = false
var is_hit: bool = false         # True while hit-stun animation is playing
var target: Node2D = null        # Reference to the player when in detection range
var jump_cooldown_timer: float = 0.0
var hp: int = MAX_HP

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: Area2D = %KillZone
@onready var right_shape: CollisionShape2D = %KillZone/RightShape2D
@onready var left_shape: CollisionShape2D = %KillZone/LeftShape2D
@onready var detection_zone: Area2D = $DetectionZone  # Large zone — triggers chasing
@onready var attack_zone: Area2D = $AttackZone        # Small zone — triggers melee swing
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var death_sound: AudioStreamPlayer2D = $DeathSound
@onready var jump_hit: Area2D = $OrcJumpHit           # Area on top of the orc's head


func _ready() -> void:
	add_to_group("Enemy")
	# Make sure hitbox is fully off before any attack starts
	_disable_hitbox()
	animated_sprite.frame_changed.connect(_on_frame_changed)
	sword_hitbox.body_entered.connect(_on_sword_hit)
	jump_hit.body_entered.connect(_on_jump_hit)


func _physics_process(delta: float) -> void:
	if dead:
		return

	# During hit-stun: freeze horizontal movement but keep gravity
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

	# Poll detection zone every frame instead of using body_exited signals.
	# This prevents losing the player when they jump over the orc.
	var bodies = detection_zone.get_overlapping_bodies()
	var player_detected = false
	for body in bodies:
		if body.is_in_group("Player"):
			target = body
			player_detected = true
			break

	# Player left detection range — go back to idle
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
	# Keep sword hitbox side in sync with facing direction
	_update_sword_shape()

	# Use get_overlapping_bodies() so it works even if the player was already inside on enter
	var player_in_attack_zone = target in attack_zone.get_overlapping_bodies()

	if player_in_attack_zone:
		# Stop moving and start swinging
		velocity.x = 0
		if not is_attacking:
			_attack()
	else:
		# Cancel swing if the player escaped mid-attack
		if is_attacking:
			_cancel_attack()
		# Chase the player
		velocity.x = direction.x * SPEED
		animated_sprite.play("orc_walk")

	move_and_slide()


func _jump() -> void:
	velocity.y = JUMP_VELOCITY
	jump_cooldown_timer = JUMP_COOLDOWN


# --- Hitbox helpers ---

# Fully disable sword monitoring and both collision shapes
func _disable_hitbox() -> void:
	sword_hitbox.set_deferred("monitoring", false)
	right_shape.set_deferred("disabled", true)
	left_shape.set_deferred("disabled", true)


# Enable only the shape on the side the orc is currently facing
func _update_sword_shape() -> void:
	right_shape.set_deferred("disabled", animated_sprite.flip_h)
	left_shape.set_deferred("disabled", not animated_sprite.flip_h)


# --- Attack ---

func _attack() -> void:
	if is_attacking:
		return
	is_attacking = true
	animated_sprite.play("orc_fighting")
	animated_sprite.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)


# Cleanly interrupt an ongoing attack without leaving the hitbox active
func _cancel_attack() -> void:
	is_attacking = false
	_disable_hitbox()
	# Disconnect to avoid ghost callbacks after cancellation
	if animated_sprite.animation_finished.is_connected(_on_attack_finished):
		animated_sprite.animation_finished.disconnect(_on_attack_finished)


# Activate hitbox only on frames where the sword is visually extended
func _on_frame_changed() -> void:
	if animated_sprite.animation == "orc_fighting":
		var sword_active = animated_sprite.frame in SWORD_ACTIVE_FRAMES
		sword_hitbox.set_deferred("monitoring", sword_active)
		if sword_active:
			_update_sword_shape()
		else:
			right_shape.set_deferred("disabled", true)
			left_shape.set_deferred("disabled", true)
	else:
		# Any non-attack animation — keep everything off
		_disable_hitbox()


func _on_attack_finished() -> void:
	is_attacking = false
	_disable_hitbox()
	# No target — just stand idle
	if target == null:
		animated_sprite.play("orc_idle")
		return
	# Re-enter attack or resume chasing depending on player position
	var player_in_attack_zone = target in attack_zone.get_overlapping_bodies()
	if player_in_attack_zone:
		_attack()
	else:
		animated_sprite.play("orc_walk")


# --- Damage & death ---

# Player touched by the sword — instant kill
func _on_sword_hit(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.die()


# Player jumped on top of the orc
func _on_jump_hit(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	# Only count as a stomp if the player is actually falling downward
	if body.velocity.y > 0.0:
		body.bounce()  # Launch the player upward immediately
		take_damage()


func take_damage() -> void:
	# Ignore hits during death sequence or active hit-stun
	if dead or is_hit:
		return
	hp -= 1
	if hp <= 0:
		_die()
	else:
		# Play sound only when the orc survives the hit
		hit_sound.play()
		_play_hit_stun()


func _play_hit_stun() -> void:
	# Interrupt any ongoing attack before entering stun
	if is_attacking:
		_cancel_attack()
	is_hit = true
	animated_sprite.play("orc_hit")
	# Use a timer (not animation_finished) to guarantee is_hit always resets
	await get_tree().create_timer(HIT_STUN_DURATION).timeout
	is_hit = false


func _die() -> void:
	dead = true
	is_hit = false
	is_attacking = false
	velocity = Vector2.ZERO
	_disable_hitbox()
	# Prevent the attack callback from firing during the death sequence
	if animated_sprite.animation_finished.is_connected(_on_attack_finished):
		animated_sprite.animation_finished.disconnect(_on_attack_finished)
	# Stop physics processing — the orc should not move after death
	set_physics_process(false)
	# Slow down the animation to match the length of the death audio clip
	animated_sprite.speed_scale = DEATH_ANIM_SPEED
	animated_sprite.play("orc_death")
	death_sound.play()
	await get_tree().create_timer(DEATH_DURATION).timeout
	queue_free()
