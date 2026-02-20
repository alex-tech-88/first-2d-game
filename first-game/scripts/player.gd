extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -300.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_dead := false #death state

@onready var animated_sprite = $AnimatedSprite2D
@onready var hit_sound = $hit_sound

func _ready():
	add_to_group("Player")

func _physics_process(delta):
	if is_dead:
		# Sliding after hit
		velocity.x = move_toward(velocity.x, 0, 600 * delta) # slowed down sliding after death a little
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

	# Move
	var direction = Input.get_axis("move_left", "move_right")

	# Flip
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Movement animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")

	# Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
# Hit sound and animation 
func die():
	if is_dead:
		return
	is_dead = true
	Engine.time_scale = 0.5 
	hit_sound.play() 
	animated_sprite.play("death_hit")
	
# Hit bounce
func bounce():
	velocity.y = -250  # или JUMP_VELOCITY
