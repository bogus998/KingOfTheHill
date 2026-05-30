extends GutTest

func _start(player_count: int) -> void:
	var players: Array = []
	for i in player_count:
		players.append({"name": "P%d" % i, "is_bot": false})
	GameManager.start_game({"players": players})

func before_each() -> void:
	_start(2)

# ── Initial state ─────────────────────────────────────────────────────────────

func test_rage_starts_at_zero() -> void:
	assert_eq(DragonManager.rage, 0)

func test_not_pending_at_start() -> void:
	assert_false(DragonManager.is_awakening_pending)

func test_awakening_count_starts_at_zero() -> void:
	assert_eq(DragonManager.awakening_count, 0)

# ── Escalation thresholds by player count ─────────────────────────────────────

func test_first_threshold_2p() -> void:
	assert_eq(DragonManager.rage_threshold, 5)

func test_first_threshold_3p() -> void:
	_start(3)
	assert_eq(DragonManager.rage_threshold, 7)

func test_first_threshold_4p() -> void:
	_start(4)
	assert_eq(DragonManager.rage_threshold, 9)

# ── Rage detection per rule ───────────────────────────────────────────────────

func test_shop_refresh_adds_rage() -> void:
	CardShop.shop_refreshed.emit()
	assert_eq(DragonManager.rage, 1)

func test_rage_changed_emitted_on_report() -> void:
	watch_signals(DragonManager)
	CardShop.shop_refreshed.emit()
	assert_signal_emitted_with_parameters(DragonManager, "rage_changed", [1])

func test_damage_3plus_adds_rage() -> void:
	PlayerManager.players[0].damage_dealt_this_turn = 3
	TurnManager.turn_ended.emit(0)
	assert_eq(DragonManager.rage, 1)

func test_damage_below_3_no_rage() -> void:
	PlayerManager.players[0].damage_dealt_this_turn = 2
	TurnManager.turn_ended.emit(0)
	assert_eq(DragonManager.rage, 0)

func test_vault_streak_second_turn_adds_one() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	TurnManager.turn_started.emit(0)   # streak 1 — no rage
	assert_eq(DragonManager.rage, 0)
	TurnManager.turn_started.emit(0)   # streak 2 — +1
	assert_eq(DragonManager.rage, 1)

func test_vault_streak_third_turn_adds_two() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	TurnManager.turn_started.emit(0)   # 1
	TurnManager.turn_started.emit(0)   # 2 → +1
	TurnManager.turn_started.emit(0)   # 3 → +2
	assert_eq(DragonManager.rage, 3)

func test_leaving_vault_resets_streak() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	TurnManager.turn_started.emit(0)   # streak 1
	PlayerManager.set_position(0, PlayerData.PlayerPosition.OUTSIDE)
	TurnManager.turn_started.emit(0)   # reset to 0
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	TurnManager.turn_started.emit(0)   # streak 1 again — no rage
	assert_eq(DragonManager.rage, 0)

func test_two_buys_adds_rage_once() -> void:
	CardShop.card_purchased.emit(0, null)
	assert_eq(DragonManager.rage, 0)
	CardShop.card_purchased.emit(0, null)
	assert_eq(DragonManager.rage, 1)
	CardShop.card_purchased.emit(0, null)
	assert_eq(DragonManager.rage, 1)

func test_buy_counter_resets_each_turn() -> void:
	CardShop.card_purchased.emit(0, null)
	TurnManager.turn_started.emit(0)   # resets buy counter
	CardShop.card_purchased.emit(0, null)
	assert_eq(DragonManager.rage, 0)

# ── Latch + deferred resolution ───────────────────────────────────────────────

func _fill_to_threshold() -> void:
	for _i in DragonManager.rage_threshold:
		CardShop.shop_refreshed.emit()

func test_pending_when_threshold_reached() -> void:
	_fill_to_threshold()
	assert_true(DragonManager.is_awakening_pending)

func test_awakening_pending_signal_emitted() -> void:
	watch_signals(DragonManager)
	_fill_to_threshold()
	assert_signal_emitted(DragonManager, "awakening_pending")

func test_not_resolved_before_round_end() -> void:
	_fill_to_threshold()
	assert_eq(DragonManager.awakening_count, 0)

func test_resolved_on_round_end() -> void:
	_fill_to_threshold()
	TurnManager.round_ended.emit(1)
	assert_false(DragonManager.is_awakening_pending)
	assert_eq(DragonManager.awakening_count, 1)

func test_rage_resets_after_awakening() -> void:
	_fill_to_threshold()
	TurnManager.round_ended.emit(1)
	assert_eq(DragonManager.rage, 0)

func test_threshold_escalates_after_awakening() -> void:
	_fill_to_threshold()
	TurnManager.round_ended.emit(1)
	assert_eq(DragonManager.rage_threshold, 4)   # 2P, 2nd awakening

func test_vault_holder_evicted_on_awakening() -> void:
	PlayerManager.set_position(1, PlayerData.PlayerPosition.AT_VAULT)
	_fill_to_threshold()
	TurnManager.round_ended.emit(1)
	assert_eq(PlayerManager.players[1].position, PlayerData.PlayerPosition.OUTSIDE)

func test_round_end_without_pending_does_nothing() -> void:
	TurnManager.round_ended.emit(1)
	assert_eq(DragonManager.awakening_count, 0)
