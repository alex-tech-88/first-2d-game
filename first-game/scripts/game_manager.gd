extends Node

var score: int = 0

@onready var score_label: Label = $ScoreLabel
@onready var hud: HUD = $"../CanvasLayer/HUD"

func add_point() -> void:
	score += 1
	hud.update_coin_label(score) # updates coins in hud
	score_label.text = "You collected " + str(score) + " coins."
