extends CharacterBody2D

const SPEED: float = 130.0
const JUMP_VELOCITY: float = -300.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float
var is_dead: bool = false # death state

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_sound: AudioStreamPlayer2D = $hit_sound
@onready var jump_sound: AudioStreamPlayer2D = $jump_sound

func _ready() -> void:
	add_to_group("Player")

func _physics_process(delta: float) -> void:
	if is_dead:
		# Sliding after hit
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()

	# Move
	var direction: float = Input.get_axis("move_left", "move_right")

	# Flip
	if direction > 0.0:
		animated_sprite.flip_h = false
	elif direction < 0.0:
		animated_sprite.flip_h = true

	# Movement animations
	if is_on_floor():
		if direction == 0.0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")  
	else:
		animated_sprite.play("jump")

	# Apply movement
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()
	
# Hit sound and animation 
func die() -> void:
	if is_dead:
		return
	is_dead = true
	Engine.time_scale = 0.5 
	hit_sound.play() 
	animated_sprite.play("death_hit")
	
# Hit bounce
func bounce() -> void:
	velocity.y = -250.0  # или JUMP_VELOCITY
