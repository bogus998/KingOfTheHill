extends Control

@onready var _result_label: Label = $CenterContainer/VBox/ResultLabel
@onready var _reason_label: Label = $CenterContainer/VBox/ReasonLabel

func _ready() -> void:
	var wi := GameManager.last_winner_index
	if wi >= 0 and wi < PlayerManager.players.size():
		_result_label.text = "%s wins!" % PlayerManager.players[wi].player_name
	else:
		_result_label.text = "It's a draw!"
	_reason_label.text = "(%s)" % GameManager.last_winner_reason
	$CenterContainer/VBox/PlayAgainButton.pressed.connect(_on_play_again)
	$CenterContainer/VBox/MainMenuButton.pressed.connect(_on_main_menu)

func _on_play_again() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/setup_game.tscn")

func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
