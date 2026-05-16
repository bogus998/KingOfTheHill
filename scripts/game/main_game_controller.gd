extends Node

@onready var _safe_area: MarginContainer = $Canvas/SafeArea
@onready var _dice_pool = $Canvas/SafeArea/VBox/DicePool
@onready var _resolution_picker = $Canvas/SafeArea/VBox/ResolutionPicker
@onready var _action_bar = $Canvas/SafeArea/VBox/ActionBar
@onready var _escape_dialog = $OverlayLayer/EscapeDialog
@onready var _vault_area = $Canvas/SafeArea/VBox/HUD/VaultArea
@onready var _pass_screen = $OverlayLayer/PassDeviceScreen

var _last_roll_result: Dictionary = { "gold": 0, "gems": 0, "claws": 0, "hearts": 0 }
var _pending_attacker: int = -1
var _resolution_controller := ResolutionController.new()
var _card_effect_handler: Node = preload("res://scripts/cards/card_effect_handler.gd").new()
var _bot_brain := BotBrain.new()

func _ready() -> void:
	_apply_safe_area()

	add_child(_card_effect_handler)

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

	_pass_screen.ready_pressed.connect(func(): pass)  # hide handled inside pass_screen

	var config := GameManager.pending_config
	if config.is_empty():
		config = {"players": [
			{"name": "Thorin", "is_bot": false},
			{"name": "Bot",    "is_bot": true},
		]}
	GameManager.start_game(config)

func _apply_safe_area() -> void:
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var screen: Vector2i = DisplayServer.screen_get_size()
	# Safe area is in physical screen pixels; convert to stretched canvas units.
	var scale: Vector2 = get_viewport().get_visible_rect().size / Vector2(get_window().size)
	_safe_area.add_theme_constant_override("margin_top", int(safe.position.y * scale.y))
	_safe_area.add_theme_constant_override("margin_bottom", int((screen.y - safe.end.y) * scale.y))
	_safe_area.add_theme_constant_override("margin_left", int(safe.position.x * scale.x))
	_safe_area.add_theme_constant_override("margin_right", int((screen.x - safe.end.x) * scale.x))

func _on_turn_started(player_index: int) -> void:
	_last_roll_result = { "gold": 0, "gems": 0, "claws": 0, "hearts": 0 }
	if PlayerManager.players[player_index].is_bot:
		_run_bot_turn.call_deferred()
	else:
		_pass_screen.show_for_player(PlayerManager.players[player_index].player_name)

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	if phase == TurnManager.TurnPhase.END_TURN:
		TurnManager.next_player()

func _on_roll_completed(faces: Array) -> void:
	_last_roll_result = DiceResolver.resolve(faces)
	_action_bar.set_end_roll_enabled(true)

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
	if PlayerManager.players[defender_index].is_bot:
		if _bot_brain.decide_flee(PlayerManager.players[defender_index]):
			_on_flee()
		else:
			_on_stay()
		return
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
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/menus/game_over.tscn")

func _run_bot_turn() -> void:
	var bot_index := TurnManager.current_player_index

	# === DICE ROLL — up to 3 rolls ===
	for roll_num in range(3):
		if not TurnManager.is_game_active or TurnManager.current_phase != TurnManager.TurnPhase.DICE_ROLL:
			return
		await get_tree().create_timer(_bot_brain.get_thinking_delay()).timeout
		if not TurnManager.is_game_active or TurnManager.current_phase != TurnManager.TurnPhase.DICE_ROLL:
			return
		_dice_pool.roll_active_dice()

		if roll_num < 2:
			var holds: Array[bool] = _bot_brain.decide_holds(
					_dice_pool.get_all_faces(), PlayerManager.players[bot_index])
			for i in holds.size():
				var die = _dice_pool.get_die(i)
				if die == null:
					continue
				var is_held: bool = die.state == DieController.DieState.HELD
				if holds[i] != is_held:
					_dice_pool.toggle_hold(i)

	# === END ROLL ===
	if not TurnManager.is_game_active or TurnManager.current_phase != TurnManager.TurnPhase.DICE_ROLL:
		return
	await get_tree().create_timer(_bot_brain.get_thinking_delay()).timeout
	_on_end_roll()

	# === APPLY RESULTS ===
	if not TurnManager.is_game_active or TurnManager.current_phase != TurnManager.TurnPhase.RESOLUTION:
		return
	await get_tree().create_timer(_bot_brain.get_thinking_delay()).timeout
	_on_apply_results()

	# If escape dialog is shown (human defender), wait for them to decide
	if TurnManager.is_game_active and TurnManager.current_phase == TurnManager.TurnPhase.RESOLUTION:
		await TurnManager.phase_changed

	# === BUY CARDS ===
	if not TurnManager.is_game_active or TurnManager.current_phase != TurnManager.TurnPhase.BUY_CARDS:
		return
	await get_tree().create_timer(_bot_brain.get_thinking_delay()).timeout
	var buy_idx: int = _bot_brain.decide_buy(CardShop.visible_cards, PlayerManager.players[bot_index].gems)
	if buy_idx >= 0:
		CardShop.purchase(buy_idx, bot_index)
	_on_end_turn()
