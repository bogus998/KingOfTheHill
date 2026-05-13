extends Control

func _on_vs_ai_pressed() -> void:
	GameManager.game_mode = "vs_ai"
	get_tree().change_scene_to_file("res://scenes/menus/setup_game.tscn")

func _on_hot_seat_pressed() -> void:
	GameManager.game_mode = "hot_seat"
	get_tree().change_scene_to_file("res://scenes/menus/setup_game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
