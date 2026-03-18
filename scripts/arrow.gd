class_name Arrow extends Node2D

@export var move_speed: float = 300
@export var arrow_sound: AudioStream

var move_dir: Vector2 = Vector2.RIGHT

@onready var hurt_box: Area2D = $HurtBox
@onready var sprite_2d: Sprite2D = $Arrow
@onready var audio_stream_player: AudioStreamPlayer2D = $Arrow_sound


func _ready() -> void:
	# Flip sprite if shooting left
	if move_dir == Vector2.LEFT:
		sprite_2d.flip_h = true

	if arrow_sound:
		audio_stream_player.stream = arrow_sound
		audio_stream_player.play()

	# body_entered for walls/tilemap, area_entered for enemies
	hurt_box.body_entered.connect(_on_hurt_box_body_entered)
	hurt_box.area_entered.connect(_on_hurt_box_area_entered)


func _physics_process(delta: float) -> void:
	position += move_dir * move_speed * delta


func _on_hurt_box_area_entered(area: Area2D) -> void:
	# Hit enemy Area2D (Hitzone)
	var parent = area.get_parent()
	if parent.is_in_group("Enemy"):
		parent.take_damage()
	queue_free()


func _on_hurt_box_body_entered(body: Node2D) -> void:
	# Ignore player
	if body.is_in_group("Player"):
		return
	if body.is_in_group("Enemy"):
		body.take_damage()
	queue_free()
