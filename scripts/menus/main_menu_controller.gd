extends Control

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/setup_game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
