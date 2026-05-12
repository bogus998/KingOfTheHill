extends Node

# Wires GameManager/TurnManager/PlayerManager signals to the game UI.
# Populated milestone by milestone — see PLAN.md.

func _ready() -> void:
	GameManager.game_ended.connect(_on_game_ended)
	TurnManager.phase_changed.connect(_on_phase_changed)
	TurnManager.turn_started.connect(_on_turn_started)

func _on_phase_changed(_phase: TurnManager.TurnPhase) -> void:
	pass  # Milestone 4: show/hide DicePool, CardShop, ActionBar

func _on_turn_started(_player_index: int) -> void:
	pass  # Milestone 4: highlight active player panel, trigger bot

func _on_game_ended(_winner_index: int, _reason: String) -> void:
	pass  # Milestone 7: show GameOver overlay
