extends CharacterBody2D

const SPEED: float = 60.0

var dead: bool = false
var is_attacking: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: Area2D = %KillZone
@onready var detection_zone: Area2D = $DetectionZone


func _ready() -> void:
	add_to_group("Enemy")
	sword_hitbox.monitoring = false
	animated_sprite.frame_changed.connect(_on_frame_changed)
	detection_zone.body_entered.connect(_on_detection_zone_body_entered)
	sword_hitbox.body_entered.connect(_on_sword_hit)


func _on_frame_changed() -> void:
	if animated_sprite.animation == "orc_fighting":
		# Enable hitbox only on frames where sword is extended
		sword_hitbox.monitoring = animated_sprite.frame in [3, 4, 9, 10]


func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") and not is_attacking:
		_attack()


func _attack() -> void:
	is_attacking = true
	animated_sprite.play("orc_fighting")
	animated_sprite.animation_finished.connect(_on_attack_finished, CONNECT_ONE_SHOT)


func _on_attack_finished() -> void:
	is_attacking = false
	sword_hitbox.monitoring = false
	animated_sprite.play("orc_idle")


func _on_sword_hit(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.die()


func take_damage() -> void:
	if dead:
		return
	dead = true
	sword_hitbox.monitoring = false
	animated_sprite.play("orc_death")
	await get_tree().create_timer(1.0).timeout
	queue_free()
