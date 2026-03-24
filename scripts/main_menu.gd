extends Control

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")


func _on_options_pressed() -> void:
	print("Options pressed")


func _on_quit_pressed() -> void:
	get_tree().quit()
