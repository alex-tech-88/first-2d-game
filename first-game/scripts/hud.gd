extends Control
class_name HUD

@export var coin_label : Label

func update_coin_label(number : int): 
	coin_label.text = "x" + str(number)
