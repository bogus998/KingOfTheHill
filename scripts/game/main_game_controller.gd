extends Node

@onready var _dice_pool = $Canvas/VBox/DicePool
@onready var _resolution_picker = $Canvas/VBox/ResolutionPicker
@onready var _action_bar = $Canvas/VBox/ActionBar
@onready var _escape_dialog = $Canvas/EscapeDialog
@onready var _vault_area = $Canvas/VBox/HUD/VaultArea

var _last_roll_result: Dictionary = { "gold": 0, "gems": 0, "claws": 0, "hearts": 0 }
var _pending_attacker: int = -1
var _resolution_controller: Node = preload("res://scripts/game/resolution_controller.gd").new()

func _ready() -> void:
	add_child(_resolution_controller)

	GameManager.game_ended.connect(_on_game_ended)
	TurnManager.phase_changed.connect(_on_phase_changed)
	TurnManager.turn_started.connect(_on_turn_started)

	_dice_pool.roll_completed.connect(_on_roll_completed)
	_action_bar.end_roll_requested.connect(_on_end_roll)
	_action_bar.end_turn_requested.connect(_on_end_turn)
	_resolution_picker.apply_requested.connect(_on_apply_results)

	_vault_area.vault_entered.connect(_on_vault_entered)
	_vault_area.vault_attacked.connect(_on_vault_attacked)
	_vault_area.escape_requested.connect(_on_escape_requested)

	_escape_dialog.flee_pressed.connect(_on_flee)
	_escape_dialog.stay_pressed.connect(_on_stay)

	# Temporary auto-start; replaced by setup menu in Milestone 7
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})

func _on_turn_started(_player_index: int) -> void:
	_last_roll_result = { "gold": 0, "gems": 0, "claws": 0, "hearts": 0 }

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	if phase == TurnManager.TurnPhase.END_TURN:
		TurnManager.next_player()

func _on_roll_completed(faces: Array) -> void:
	_last_roll_result = DiceResolver.resolve(faces)

func _on_end_roll() -> void:
	TurnManager.advance_phase()  # DICE_ROLL → RESOLUTION
	_resolution_picker.show_result(_last_roll_result)

func _on_apply_results() -> void:
	var player_idx := TurnManager.current_player_index
	_resolution_controller.apply_non_claw(player_idx, _last_roll_result)
	_resolution_picker.hide_picker()

	if _last_roll_result["claws"] > 0:
		# vault_entered / vault_attacked / escape_requested fires synchronously inside handle_claws
		_vault_area.handle_claws(player_idx, _last_roll_result["claws"])
		# Phase advance is done inside _on_vault_entered, _on_vault_attacked, or after dialog
	else:
		TurnManager.advance_phase()  # RESOLUTION → BUY_CARDS

func _on_vault_entered(_player_index: int) -> void:
	TurnManager.advance_phase()

func _on_vault_attacked(_attacker: int, _claws: int) -> void:
	TurnManager.advance_phase()

func _on_escape_requested(attacker_index: int, defender_index: int) -> void:
	_pending_attacker = attacker_index
	var attacker_name := PlayerManager.players[attacker_index].player_name
	var defender_name := PlayerManager.players[defender_index].player_name
	_escape_dialog.show_dialog(attacker_name, defender_name)

func _on_flee() -> void:
	_vault_area.handle_flee(_pending_attacker)
	_escape_dialog.hide_dialog()
	_pending_attacker = -1
	TurnManager.advance_phase()

func _on_stay() -> void:
	_escape_dialog.hide_dialog()
	_pending_attacker = -1
	TurnManager.advance_phase()

func _on_end_turn() -> void:
	TurnManager.advance_phase()  # BUY_CARDS → END_TURN (triggers next_player via _on_phase_changed)

func _on_game_ended(winner_index: int, reason: String) -> void:
	if winner_index >= 0:
		print("Game Over! Winner: %s (%s)" % [
			PlayerManager.players[winner_index].player_name, reason
		])
	else:
		print("Game Over! Draw!")
