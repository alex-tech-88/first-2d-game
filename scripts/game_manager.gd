extends Node

# Coins required to unlock the portal on this level
const COINS_TO_WIN: int = 6

var score: int = 0

@onready var score_label: Label = $ScoreLabel
@onready var hud: HUD = $"../UI/HUD"

func add_point() -> void:
	score += 1
	hud.update_coin_label(score)
	score_label.text = "You collected " + str(score) + " coins."

# Returns true when the player has collected enough coins to proceed
func has_enough_coins() -> bool:
	return score >= COINS_TO_WIN
