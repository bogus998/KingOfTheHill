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

# ── Dragon dice resolution (deterministic stub dice) ──────────────────────────

class _FireDice extends DragonDice:
	func roll_action() -> Action: return Action.FIRE
	func roll_fire() -> int: return 2

class _HoardDice extends DragonDice:
	func roll_action() -> Action: return Action.HOARD
	func roll_hoard() -> int: return 3

class _SlumberDice extends DragonDice:
	func roll_action() -> Action: return Action.SLUMBER

class _EnvDice extends DragonDice:
	func roll_action() -> Action: return Action.ENVIRONMENT

class _WrathDice extends DragonDice:
	func roll_action() -> Action: return Action.WRATH
	func roll_fire() -> int: return 1
	func roll_hoard() -> int: return 2

func _awaken_with(stub: DragonDice) -> Dictionary:
	DragonManager._dice = stub
	watch_signals(DragonManager)
	_fill_to_threshold()
	TurnManager.round_ended.emit(1)
	var params = get_signal_parameters(DragonManager, "awakening_resolved")
	return params[0] if params != null else {}

func test_fire_damages_all_players() -> void:
	var hp0 := PlayerManager.players[0].health
	var hp1 := PlayerManager.players[1].health
	_awaken_with(_FireDice.new())
	assert_eq(PlayerManager.players[0].health, hp0 - 2)
	assert_eq(PlayerManager.players[1].health, hp1 - 2)

func test_hoard_reduces_gold_capped_at_zero() -> void:
	PlayerManager.add_gold(0, 5)
	var g0 := PlayerManager.players[0].gold
	var g1 := PlayerManager.players[1].gold
	_awaken_with(_HoardDice.new())
	assert_eq(PlayerManager.players[0].gold, maxi(0, g0 - 3))
	assert_eq(PlayerManager.players[1].gold, maxi(0, g1 - 3))

func test_slumber_does_nothing() -> void:
	var hp0 := PlayerManager.players[0].health
	var g0 := PlayerManager.players[0].gold
	_awaken_with(_SlumberDice.new())
	assert_eq(PlayerManager.players[0].health, hp0)
	assert_eq(PlayerManager.players[0].gold, g0)

func test_environment_flags_draw_in_summary() -> void:
	var summary := _awaken_with(_EnvDice.new())
	assert_true(summary.get("draw_environment", false))

func test_wrath_applies_fire_hoard_and_draw() -> void:
	var hp0 := PlayerManager.players[0].health
	var g0 := PlayerManager.players[0].gold
	var summary := _awaken_with(_WrathDice.new())
	assert_eq(PlayerManager.players[0].health, hp0 - 1)
	assert_eq(PlayerManager.players[0].gold, maxi(0, g0 - 2))
	assert_true(summary.get("draw_environment", false))

func test_dragon_die_rolled_emitted() -> void:
	DragonManager._dice = _FireDice.new()
	watch_signals(DragonManager)
	_fill_to_threshold()
	TurnManager.round_ended.emit(1)
	assert_signal_emitted(DragonManager, "dragon_die_rolled")
