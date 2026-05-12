extends Node

@onready var _dice_pool = $DicePool

func _ready() -> void:
	GameManager.game_ended.connect(_on_game_ended)
	TurnManager.phase_changed.connect(_on_phase_changed)
	TurnManager.turn_started.connect(_on_turn_started)
	_dice_pool.roll_completed.connect(_on_roll_completed)

func _on_phase_changed(_phase: TurnManager.TurnPhase) -> void:
	pass  # Milestone 4: show/hide panels

func _on_turn_started(_player_index: int) -> void:
	pass  # Milestone 4: highlight panel, trigger bot

func _on_game_ended(_winner_index: int, _reason: String) -> void:
	pass  # Milestone 7: show GameOver overlay

func _on_roll_completed(faces: Array) -> void:
	var result := DiceResolver.resolve(faces)
	print("Roll: gold=%d gems=%d claws=%d hearts=%d" % [
		result["gold"], result["gems"], result["claws"], result["hearts"]
	])
