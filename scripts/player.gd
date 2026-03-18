extends CharacterBody2D

# Movement constants
const SPEED: float = 130.0
const JUMP_VELOCITY: float = -300.0
const DEATH_SLIDE_DECELERATION: float = 600.0
const BOUNCE_VELOCITY: float = -250.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

# State flags
var is_dead: bool = false
var is_shooting: bool = false
var can_coyote_jump: bool = false
var jump_buffered: bool = false

@export var arrow_scene: PackedScene

# Node references
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_sound: AudioStreamPlayer2D = $hit_sound
@onready var jump_sound: AudioStreamPlayer2D = $jump_sound
@onready var coyote_time: Timer = $CoyoteTime
@onready var jump_buffer: Timer = $JumpBuffer
@onready var shoot_cooldown: Timer = $ShootCooldown


func _ready() -> void:
	add_to_group("Player")


func _physics_process(delta: float) -> void:
	var was_on_floor: bool = is_on_floor()

	if is_dead:
		_handle_death_physics(delta)
		move_and_slide()
		return

	_apply_gravity(delta)
	_store_jump_input()
	_try_jump()

	var direction: float = Input.get_axis("move_left", "move_right")

	_update_sprite_direction(direction)
	_update_horizontal_movement(direction)
	move_and_slide()
	_update_coyote_time(was_on_floor)
	_update_animations(direction)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and not is_dead:
		_shoot()


func _shoot() -> void:
	# Ignore if no arrow, cooldown active, or already shooting
	if arrow_scene == null or not shoot_cooldown.is_stopped() or is_shooting:
		return

	shoot_cooldown.start()
	is_shooting = true
	animated_sprite.play("bow")
	animated_sprite.animation_finished.connect(_on_bow_finished, CONNECT_ONE_SHOT)


func _on_bow_finished() -> void:
	is_shooting = false

	if arrow_scene:
		var arrow := arrow_scene.instantiate() as Arrow
		# Set direction based on sprite facing
		arrow.move_dir = Vector2.LEFT if animated_sprite.flip_h else Vector2.RIGHT
		# Offset spawn position forward and slightly up
		var offset = Vector2(30, 0) * arrow.move_dir + Vector2(0, -5)
		arrow.global_position = global_position + offset
		get_tree().current_scene.add_child(arrow)

	animated_sprite.play("idle")


func _handle_death_physics(delta: float) -> void:
	# Slow down horizontally, keep falling
	velocity.x = move_toward(velocity.x, 0.0, DEATH_SLIDE_DECELERATION * delta)
	_apply_gravity(delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta


func _store_jump_input() -> void:
	# Buffer jump input for a short window
	if Input.is_action_just_pressed("jump"):
		jump_buffered = true
		jump_buffer.start()


func _try_jump() -> void:
	if jump_buffered and (is_on_floor() or can_coyote_jump):
		do_jump()


func do_jump() -> void:
	velocity.y = JUMP_VELOCITY
	jump_sound.play()
	jump_buffered = false
	can_coyote_jump = false
	jump_buffer.stop()
	coyote_time.stop()


func _update_sprite_direction(direction: float) -> void:
	if direction > 0.0:
		animated_sprite.flip_h = false
	elif direction < 0.0:
		animated_sprite.flip_h = true


func _update_horizontal_movement(direction: float) -> void:
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		# Decelerate to stop
		velocity.x = move_toward(velocity.x, 0.0, SPEED)


func _update_coyote_time(was_on_floor: bool) -> void:
	# Allow jump briefly after walking off edge
	if was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		can_coyote_jump = true
		coyote_time.start()

	if is_on_floor():
		can_coyote_jump = false
		if jump_buffered:
			do_jump()


func _update_animations(direction: float) -> void:
	if is_dead:
		return
	# Don't interrupt bow animation
	if is_shooting:
		return

	if is_on_floor():
		if direction == 0.0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")


func _on_coyote_time_timeout() -> void:
	can_coyote_jump = false


func _on_jump_buffer_timeout() -> void:
	jump_buffered = false


func die() -> void:
	if is_dead:
		return
	is_dead = true
	Engine.time_scale = 0.5
	hit_sound.play()
	animated_sprite.play("death_hit")


func bounce() -> void:
	velocity.y = BOUNCE_VELOCITY
