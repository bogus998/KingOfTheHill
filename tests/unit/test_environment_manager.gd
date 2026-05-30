extends GutTest

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})

func after_each() -> void:
	EnvironmentManager.active_card = null
	EnvironmentManager.pending_card = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func test_starts_with_no_card() -> void:
	assert_null(EnvironmentManager.active_card)
	assert_null(EnvironmentManager.pending_card)

func test_draw_queues_pending() -> void:
	EnvironmentManager.draw_and_queue()
	assert_not_null(EnvironmentManager.pending_card)
	assert_null(EnvironmentManager.active_card)

func test_pending_promotes_on_round_start() -> void:
	EnvironmentManager.draw_and_queue()
	TurnManager.round_started.emit(2)
	assert_not_null(EnvironmentManager.active_card)
	assert_null(EnvironmentManager.pending_card)

func test_active_dismissed_on_round_end() -> void:
	EnvironmentManager.draw_and_queue()
	TurnManager.round_started.emit(2)
	TurnManager.round_ended.emit(2)
	assert_null(EnvironmentManager.active_card)

func test_card_activated_signal() -> void:
	EnvironmentManager.draw_and_queue()
	watch_signals(EnvironmentManager)
	TurnManager.round_started.emit(2)
	assert_signal_emitted(EnvironmentManager, "card_activated")

func test_only_one_active_after_redraw() -> void:
	EnvironmentManager.draw_and_queue()
	TurnManager.round_started.emit(2)
	var first := EnvironmentManager.active_card
	EnvironmentManager.draw_and_queue()
	TurnManager.round_started.emit(3)
	assert_not_null(EnvironmentManager.active_card)
	assert_ne(EnvironmentManager.active_card, first)

# ── Query delegation ──────────────────────────────────────────────────────────

func test_queries_neutral_when_inactive() -> void:
	EnvironmentManager.active_card = null
	assert_eq(EnvironmentManager.roll_limit(), -1)
	assert_eq(EnvironmentManager.dice_count_delta(), 0)
	assert_eq(EnvironmentManager.shop_cost_delta(), 0)
	assert_eq(EnvironmentManager.damage_cap(), -1)
	assert_true(EnvironmentManager.purchasing_allowed())
	assert_true(EnvironmentManager.cards_active())
	assert_false(EnvironmentManager.grants_free_reroll())

func test_query_delegates_silence() -> void:
	EnvironmentManager.active_card = SilenceEffect.new()
	assert_false(EnvironmentManager.cards_active())

func test_query_delegates_drought() -> void:
	EnvironmentManager.active_card = DroughtEffect.new()
	assert_eq(EnvironmentManager.shop_cost_delta(), 1)

func test_query_delegates_trembling_ground() -> void:
	EnvironmentManager.active_card = TremblingGroundEffect.new()
	assert_eq(EnvironmentManager.roll_limit(), 2)

# ── Reactive effects (active card set directly) ───────────────────────────────

func test_ricochet_hits_attacker() -> void:
	EnvironmentManager.active_card = RicochetEffect.new()
	var hp_attacker := PlayerManager.players[0].health
	PlayerManager.apply_damage(1, 2, 0)
	assert_eq(PlayerManager.players[0].health, hp_attacker - 1)

func test_gold_fever_damages_on_gold_gain() -> void:
	EnvironmentManager.active_card = GoldFeverEffect.new()
	var hp0 := PlayerManager.players[0].health
	PlayerManager.add_gold(0, 3)
	assert_eq(PlayerManager.players[0].health, hp0 - 3)

func test_tax_collection_charges_gold() -> void:
	EnvironmentManager.active_card = TaxCollectionEffect.new()
	PlayerManager.add_gold(0, 2)
	var g0 := PlayerManager.players[0].gold
	TurnManager.round_ended.emit(1)
	assert_eq(PlayerManager.players[0].gold, g0 - 1)

func test_tax_collection_damages_when_broke() -> void:
	EnvironmentManager.active_card = TaxCollectionEffect.new()
	PlayerManager.players[0].gold = 0
	var hp0 := PlayerManager.players[0].health
	TurnManager.round_ended.emit(1)
	assert_eq(PlayerManager.players[0].health, hp0 - 1)

func test_lonely_crown_damages_vault_holder() -> void:
	EnvironmentManager.active_card = LonelyCrownEffect.new()
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	var hp0 := PlayerManager.players[0].health
	TurnManager.round_ended.emit(1)
	assert_eq(PlayerManager.players[0].health, hp0 - 1)

func test_frenzy_rewards_top_damage_dealer() -> void:
	var f := FrenzyEffect.new()
	f.on_round_started()
	EnvironmentManager.active_card = f
	PlayerManager.apply_damage(1, 4, 0)
	PlayerManager.apply_damage(0, 1, 1)
	var g0 := PlayerManager.players[0].gold
	TurnManager.round_ended.emit(1)
	assert_eq(PlayerManager.players[0].gold, g0 + 3)

func test_golden_roll_via_notify() -> void:
	EnvironmentManager.active_card = GoldenRollEffect.new()
	var gems0 := PlayerManager.players[0].gems
	EnvironmentManager.notify_roll_finalized(0, 1, [])
	assert_eq(PlayerManager.players[0].gems, gems0 + 2)

func test_gem_surge_via_notify() -> void:
	EnvironmentManager.active_card = GemSurgeEffect.new()
	var gems0 := PlayerManager.players[0].gems
	var heart := DiceResolver.DieFace.HEART
	EnvironmentManager.notify_roll_finalized(0, 2, [heart, heart, 1])
	assert_eq(PlayerManager.players[0].gems, gems0 + 1)

func test_tremor_discards_a_card() -> void:
	PlayerManager.add_card_to_hand(0, CardData.new())
	var before := PlayerManager.players[0].cards_in_hand.size()
	var t := TremorEffect.new()
	EnvironmentManager.active_card = t
	t.on_round_started()
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), before - 1)
