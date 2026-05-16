extends Node

signal game_started
signal game_ended(winner_index: int, reason: String)

var pending_config: Dictionary = {}
var last_winner_index: int = -1
var last_winner_reason: String = ""

func start_game(config: Dictionary) -> void:
	var player_configs: Array[Dictionary] = []
	player_configs.assign(config.get("players", []))
	PlayerManager.setup(player_configs)
	if not PlayerManager.win_condition_met.is_connected(_on_win_condition_met):
		PlayerManager.win_condition_met.connect(_on_win_condition_met)
	CardShop.reset()
	TurnManager.begin()
	game_started.emit()

func declare_winner(winner_index: int, reason: String) -> void:
	TurnManager.is_game_active = false
	last_winner_index = winner_index
	last_winner_reason = reason
	game_ended.emit(winner_index, reason)

func _on_win_condition_met(winner_index: int, reason: String) -> void:
	declare_winner(winner_index, reason)
