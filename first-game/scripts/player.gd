extends CharacterBody2D

# Movement constants
const SPEED: float = 130.0
const JUMP_VELOCITY: float = -300.0
const DEATH_SLIDE_DECELERATION: float = 600.0
const BOUNCE_VELOCITY: float = -250.0

# Physics
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

# States
var is_dead: bool = false # death state
var can_coyote_jump: bool = false # allows jump shortly after leaving platform
var jump_buffered: bool = false # stores early jump input before landing

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_sound: AudioStreamPlayer2D = $hit_sound
@onready var jump_sound: AudioStreamPlayer2D = $jump_sound
@onready var coyote_time: Timer = $CoyoteTime
@onready var jump_buffer: Timer = $JumpBuffer


func _ready() -> void:
	# Add player to group for enemy detection
	add_to_group("Player")


func _physics_process(delta: float) -> void:
	# Remember if player was on floor before physics step
	var was_on_floor: bool = is_on_floor()

	# Death physics (reduced control, sliding)
	if is_dead:
		_handle_death_physics(delta)
		move_and_slide()
		return

	# Apply gravity when in air
	_apply_gravity(delta)

	# Save jump input into jump buffer
	_store_jump_input()

	# Try executing jump (normal jump, coyote time or buffered jump)
	_try_jump()

	# Get horizontal input
	var direction: float = Input.get_axis("move_left", "move_right")

	# Flip sprite depending on direction
	_update_sprite_direction(direction)

	# Apply horizontal movement
	_update_horizontal_movement(direction)

	# Apply physics movement
	move_and_slide()

	# Handle coyote time after movement
	_update_coyote_time(was_on_floor)

	# Update animations based on state
	_update_animations(direction)


# Handles reduced movement after player death
func _handle_death_physics(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, DEATH_SLIDE_DECELERATION * delta)
	_apply_gravity(delta)


# Applies gravity when not on floor
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


# Stores jump input for jump buffer
func _store_jump_input() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffered = true
		jump_buffer.start()


# Attempts to execute a jump
func _try_jump() -> void:
	if jump_buffered and (is_on_floor() or can_coyote_jump):
		do_jump()


# Performs the jump
func do_jump() -> void:
	velocity.y = JUMP_VELOCITY
	jump_sound.play()

	jump_buffered = false
	can_coyote_jump = false

	jump_buffer.stop()
	coyote_time.stop()


# Flips sprite depending on movement direction
func _update_sprite_direction(direction: float) -> void:
	if direction > 0.0:
		animated_sprite.flip_h = false
	elif direction < 0.0:
		animated_sprite.flip_h = true


# Handles horizontal movement
func _update_horizontal_movement(direction: float) -> void:
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)


# Starts coyote time when player walks off platform
func _update_coyote_time(was_on_floor: bool) -> void:
	if was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		can_coyote_jump = true
		coyote_time.start()

	# Reset coyote state when standing on floor
	if is_on_floor():
		can_coyote_jump = false

		# If jump was buffered before landing -> jump immediately
		if jump_buffered:
			do_jump()


# Handles animations
func _update_animations(direction: float) -> void:
	if is_dead:
		return

	if is_on_floor():
		if direction == 0.0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")


# Coyote time timer timeout
func _on_coyote_time_timeout() -> void:
	can_coyote_jump = false


# Jump buffer timer timeout
func _on_jump_buffer_timeout() -> void:
	jump_buffered = false


# Player death
func die() -> void:
	if is_dead:
		return

	is_dead = true
	Engine.time_scale = 0.5
	hit_sound.play()
	animated_sprite.play("death_hit")


# Enemy stomp bounce
func bounce() -> void:
	velocity.y = BOUNCE_VELOCITY
