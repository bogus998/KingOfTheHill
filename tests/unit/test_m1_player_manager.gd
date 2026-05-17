extends GutTest

func before_each() -> void:
	PlayerManager.setup([
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	])

# ── Initial state ─────────────────────────────────────────────────────────────

func test_initial_health_is_10() -> void:
	assert_eq(PlayerManager.players[0].health, 10)

func test_initial_gems_is_0() -> void:
	assert_eq(PlayerManager.players[0].gems, 0)

func test_initial_gold_is_0() -> void:
	assert_eq(PlayerManager.players[0].gold, 0)

func test_initial_position_is_outside() -> void:
	assert_eq(PlayerManager.players[0].position, PlayerData.PlayerPosition.OUTSIDE)

func test_initial_is_not_eliminated() -> void:
	assert_false(PlayerManager.players[0].is_eliminated)

# ── apply_damage ──────────────────────────────────────────────────────────────

func test_damage_reduces_health() -> void:
	PlayerManager.apply_damage(0, 3)
	assert_eq(PlayerManager.players[0].health, 7)

func test_damage_emits_player_damaged_signal() -> void:
	watch_signals(PlayerManager)
	PlayerManager.apply_damage(0, 3)
	assert_signal_emitted(PlayerManager, "player_damaged")

func test_damage_to_zero_eliminates_player() -> void:
	PlayerManager.apply_damage(0, 10)
	assert_true(PlayerManager.players[0].is_eliminated)

func test_damage_to_zero_emits_player_eliminated() -> void:
	watch_signals(PlayerManager)
	PlayerManager.apply_damage(0, 10)
	assert_signal_emitted(PlayerManager, "player_eliminated")

func test_damage_does_not_go_below_zero() -> void:
	PlayerManager.apply_damage(0, 99)
	assert_eq(PlayerManager.players[0].health, 0)

# ── apply_heal ────────────────────────────────────────────────────────────────

func test_heal_restores_health() -> void:
	PlayerManager.apply_damage(0, 5)
	PlayerManager.apply_heal(0, 3)
	assert_eq(PlayerManager.players[0].health, 8)

func test_heal_capped_at_max() -> void:
	PlayerManager.apply_heal(0, 5)
	assert_eq(PlayerManager.players[0].health, 10)

func test_heal_ignored_at_vault() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	PlayerManager.apply_damage(0, 4)
	PlayerManager.apply_heal(0, 4)
	assert_eq(PlayerManager.players[0].health, 6)

# ── add_gems / win condition ──────────────────────────────────────────────────

func test_add_gems_updates_balance() -> void:
	PlayerManager.add_gems(0, 5)
	assert_eq(PlayerManager.players[0].gems, 5)

func test_add_gems_emits_gem_changed() -> void:
	watch_signals(PlayerManager)
	PlayerManager.add_gems(0, 5)
	assert_signal_emitted(PlayerManager, "gem_changed")

func test_20_gems_emits_win_condition() -> void:
	watch_signals(PlayerManager)
	PlayerManager.add_gems(0, 20)
	assert_signal_emitted(PlayerManager, "win_condition_met")

func test_last_standing_emits_win_condition() -> void:
	watch_signals(PlayerManager)
	PlayerManager.apply_damage(1, 10)
	assert_signal_emitted(PlayerManager, "win_condition_met")

# ── gold ─────────────────────────────────────────────────────────────────────

func test_spend_gold_deducts_correctly() -> void:
	PlayerManager.add_gold(0, 5)
	PlayerManager.spend_gold(0, 3)
	assert_eq(PlayerManager.players[0].gold, 2)

func test_spend_gold_returns_true_on_success() -> void:
	PlayerManager.add_gold(0, 5)
	assert_true(PlayerManager.spend_gold(0, 5))

func test_spend_gold_returns_false_when_insufficient() -> void:
	assert_false(PlayerManager.spend_gold(0, 1))

func test_spend_gold_does_not_deduct_on_failure() -> void:
	PlayerManager.spend_gold(0, 1)
	assert_eq(PlayerManager.players[0].gold, 0)
