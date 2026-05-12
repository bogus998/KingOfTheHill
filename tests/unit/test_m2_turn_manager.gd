extends GutTest

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})

# ── Initial state ─────────────────────────────────────────────────────────────

func test_starts_at_player_0() -> void:
	assert_eq(TurnManager.current_player_index, 0)

func test_starts_at_dice_roll_phase() -> void:
	assert_eq(TurnManager.current_phase, TurnManager.TurnPhase.DICE_ROLL)

func test_game_is_active_after_start() -> void:
	assert_true(TurnManager.is_game_active)

func test_roll_count_starts_at_zero() -> void:
	assert_eq(TurnManager.roll_count, 0)

# ── Phase transitions ─────────────────────────────────────────────────────────

func test_advance_from_dice_roll_to_resolution() -> void:
	TurnManager.advance_phase()
	assert_eq(TurnManager.current_phase, TurnManager.TurnPhase.RESOLUTION)

func test_advance_from_resolution_to_buy_cards() -> void:
	TurnManager.advance_phase()
	TurnManager.advance_phase()
	assert_eq(TurnManager.current_phase, TurnManager.TurnPhase.BUY_CARDS)

func test_advance_from_buy_cards_to_end_turn() -> void:
	TurnManager.advance_phase()
	TurnManager.advance_phase()
	TurnManager.advance_phase()
	assert_eq(TurnManager.current_phase, TurnManager.TurnPhase.END_TURN)

func test_advance_emits_phase_changed() -> void:
	watch_signals(TurnManager)
	TurnManager.advance_phase()
	assert_signal_emitted(TurnManager, "phase_changed")

func test_advance_does_nothing_when_game_inactive() -> void:
	TurnManager.is_game_active = false
	TurnManager.advance_phase()
	assert_eq(TurnManager.current_phase, TurnManager.TurnPhase.DICE_ROLL)

# ── next_player ───────────────────────────────────────────────────────────────

func test_next_player_moves_to_player_1() -> void:
	_complete_turn()
	assert_eq(TurnManager.current_player_index, 1)

func test_next_player_wraps_back_to_player_0() -> void:
	_complete_turn()
	_complete_turn()
	assert_eq(TurnManager.current_player_index, 0)

func test_next_player_resets_phase_to_dice_roll() -> void:
	_complete_turn()
	assert_eq(TurnManager.current_phase, TurnManager.TurnPhase.DICE_ROLL)

func test_next_player_resets_roll_count() -> void:
	TurnManager.roll_count = 3
	_complete_turn()
	assert_eq(TurnManager.roll_count, 0)

func test_next_player_emits_turn_started() -> void:
	watch_signals(TurnManager)
	_complete_turn()
	assert_signal_emitted(TurnManager, "turn_started")

func test_turn_ended_emitted_on_advance_from_buy_cards() -> void:
	watch_signals(TurnManager)
	TurnManager.advance_phase()
	TurnManager.advance_phase()
	TurnManager.advance_phase()
	assert_signal_emitted(TurnManager, "turn_ended")

# ── Vault bonus ───────────────────────────────────────────────────────────────

func test_vault_player_gets_2_gold_at_turn_start() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	assert_eq(PlayerManager.players[0].gold, 0)
	_complete_turn()                                   # player 0 ends → player 1 starts
	var gold_before := PlayerManager.players[0].gold
	_complete_turn()                                   # player 1 ends → player 0 starts → bonus fires
	assert_eq(PlayerManager.players[0].gold, gold_before + 2)

func test_outside_player_gets_no_vault_bonus() -> void:
	var gold_before := PlayerManager.players[0].gold
	_complete_turn()
	_complete_turn()
	assert_eq(PlayerManager.players[0].gold, gold_before)

# ── Elimination skip ──────────────────────────────────────────────────────────

func test_eliminated_player_skipped_in_turn_order() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
		{"name": "Balin",  "is_bot": false},
	]})
	PlayerManager.players[1].is_eliminated = true
	_complete_turn()
	assert_eq(TurnManager.current_player_index, 2)

# ── Helper ────────────────────────────────────────────────────────────────────

func _complete_turn() -> void:
	TurnManager.advance_phase()
	TurnManager.advance_phase()
	TurnManager.advance_phase()
	TurnManager.next_player()
