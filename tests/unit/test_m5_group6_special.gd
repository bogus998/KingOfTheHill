extends GutTest

var _handler: CardEffectHandler

func before_each() -> void:
	PlayerManager.setup([
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	])
	_handler = CardEffectHandler.new()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _load_card(path: String) -> CardData:
	return load(path) as CardData

func _add_to_hand(player_index: int, card: CardData) -> CardData:
	PlayerManager.add_card_to_hand(player_index, card)
	return PlayerManager.players[player_index].cards_in_hand.back() as CardData

# ── respawn (Second Wind) ──────────────────────────────────────────────────────

func test_respawn_prevents_elimination() -> void:
	var card := _load_card("res://data/cards/card_038_second_wind.tres")
	_add_to_hand(0, card)
	PlayerManager.apply_damage(0, 10)
	assert_false(PlayerManager.players[0].is_eliminated)

func test_respawn_restores_full_health() -> void:
	var card := _load_card("res://data/cards/card_038_second_wind.tres")
	_add_to_hand(0, card)
	PlayerManager.apply_damage(0, 10)
	assert_eq(PlayerManager.players[0].health, PlayerManager.players[0].max_health)

func test_respawn_clears_all_cards() -> void:
	var respawn_card := _load_card("res://data/cards/card_038_second_wind.tres")
	var other_card := _load_card("res://data/cards/card_044_gold_battery.tres")
	_add_to_hand(0, respawn_card)
	_add_to_hand(0, other_card)
	PlayerManager.apply_damage(0, 10)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 0)

func test_respawn_resets_gems_to_zero() -> void:
	var card := _load_card("res://data/cards/card_038_second_wind.tres")
	_add_to_hand(0, card)
	PlayerManager.add_gems(0, 5)
	PlayerManager.apply_damage(0, 10)
	assert_eq(PlayerManager.players[0].gems, 0)

func test_respawn_emits_player_respawned() -> void:
	var card := _load_card("res://data/cards/card_038_second_wind.tres")
	_add_to_hand(0, card)
	watch_signals(PlayerManager)
	PlayerManager.apply_damage(0, 10)
	assert_signal_emitted(PlayerManager, "player_respawned")

func test_second_elimination_without_respawn_is_permanent() -> void:
	var card := _load_card("res://data/cards/card_038_second_wind.tres")
	_add_to_hand(0, card)
	PlayerManager.apply_damage(0, 10)   # first hit: respawn fires, hand cleared
	PlayerManager.apply_damage(0, 10)   # second hit: no card, elimination is permanent
	assert_true(PlayerManager.players[0].is_eliminated)

# ── shield_bearer ─────────────────────────────────────────────────────────────

func test_shield_bearer_prevents_elimination() -> void:
	var card := _load_card("res://data/cards/card_073_shield_bearer.tres")
	_add_to_hand(0, card)
	PlayerManager.apply_damage(0, 10)
	assert_false(PlayerManager.players[0].is_eliminated)

func test_shield_bearer_restores_full_health() -> void:
	var card := _load_card("res://data/cards/card_073_shield_bearer.tres")
	_add_to_hand(0, card)
	PlayerManager.apply_damage(0, 10)
	assert_eq(PlayerManager.players[0].health, PlayerManager.players[0].max_health)

func test_shield_bearer_consumed_on_use() -> void:
	var card := _load_card("res://data/cards/card_073_shield_bearer.tres")
	_add_to_hand(0, card)
	PlayerManager.apply_damage(0, 10)
	var has_shield := false
	for c in PlayerManager.players[0].cards_in_hand:
		if c.effect != null and c.effect.effect_id == CardEffectId.Id.SHIELD_BEARER:
			has_shield = true
	assert_false(has_shield)

func test_shield_bearer_keeps_other_cards() -> void:
	var shield := _load_card("res://data/cards/card_073_shield_bearer.tres")
	var other := _load_card("res://data/cards/card_044_gold_battery.tres")
	_add_to_hand(0, shield)
	_add_to_hand(0, other)
	PlayerManager.apply_damage(0, 10)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 1)

func test_shield_bearer_resets_gems_to_zero() -> void:
	var card := _load_card("res://data/cards/card_073_shield_bearer.tres")
	_add_to_hand(0, card)
	PlayerManager.add_gems(0, 5)
	PlayerManager.apply_damage(0, 10)
	assert_eq(PlayerManager.players[0].gems, 0)

func test_shield_bearer_checked_before_respawn() -> void:
	var shield := _load_card("res://data/cards/card_073_shield_bearer.tres")
	var respawn := _load_card("res://data/cards/card_038_second_wind.tres")
	_add_to_hand(0, shield)
	_add_to_hand(0, respawn)
	PlayerManager.apply_damage(0, 10)
	# Shield fires first: keeps cards (including respawn), only removes shield
	var has_respawn := false
	for c in PlayerManager.players[0].cards_in_hand:
		if c.effect != null and c.effect.effect_id == CardEffectId.Id.RESPAWN:
			has_respawn = true
	assert_true(has_respawn)

# ── extra_turn (Bloodlust) ────────────────────────────────────────────────────

func test_extra_turn_sets_pending_flag() -> void:
	var card := _load_card("res://data/cards/card_029_bloodlust.tres")
	_add_to_hand(0, card)
	var in_hand: CardData = PlayerManager.players[0].cards_in_hand.back() as CardData
	TurnManager.pending_extra_turn = false
	_handler.apply_immediate(in_hand, 0)
	assert_true(TurnManager.pending_extra_turn)
	TurnManager.pending_extra_turn = false  # cleanup

func test_extra_turn_card_removed_from_hand_after_use() -> void:
	var card := _load_card("res://data/cards/card_029_bloodlust.tres")
	_add_to_hand(0, card)
	var in_hand: CardData = PlayerManager.players[0].cards_in_hand.back() as CardData
	_handler.apply_immediate(in_hand, 0)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 0)
	TurnManager.pending_extra_turn = false  # cleanup

# ── gold_battery ──────────────────────────────────────────────────────────────

func test_gold_battery_charges_set_on_purchase() -> void:
	var card := _load_card("res://data/cards/card_044_gold_battery.tres")
	_add_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	var in_hand: CardData = PlayerManager.players[0].cards_in_hand.back() as CardData
	assert_eq(in_hand.charges, 6)

func test_gold_battery_grants_gold_on_turn_start() -> void:
	var card := _load_card("res://data/cards/card_044_gold_battery.tres")
	_add_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	var gold_before: int = PlayerManager.players[0].gold
	_handler._on_turn_started(0)
	assert_eq(PlayerManager.players[0].gold, gold_before + 2)

func test_gold_battery_decrements_charge_on_turn_start() -> void:
	var card := _load_card("res://data/cards/card_044_gold_battery.tres")
	_add_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	_handler._on_turn_started(0)
	var in_hand: CardData = PlayerManager.players[0].cards_in_hand.back() as CardData
	assert_eq(in_hand.charges, 5)

func test_gold_battery_removed_when_charges_depleted() -> void:
	var card := _load_card("res://data/cards/card_044_gold_battery.tres")
	_add_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	var in_hand: CardData = PlayerManager.players[0].cards_in_hand.back() as CardData
	in_hand.charges = 1
	_handler._on_turn_started(0)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 0)

func test_gold_battery_each_player_gets_own_charges() -> void:
	var card := _load_card("res://data/cards/card_044_gold_battery.tres")
	_add_to_hand(0, card)
	_add_to_hand(1, card)
	_handler._on_card_purchased(0, card)
	_handler._on_card_purchased(1, card)
	var p0_card: CardData = PlayerManager.players[0].cards_in_hand.back() as CardData
	var p1_card: CardData = PlayerManager.players[1].cards_in_hand.back() as CardData
	assert_ne(p0_card, p1_card)
	p0_card.charges = 3
	assert_eq(p1_card.charges, 6)  # p1's copy is unaffected

# ── recycle / mimic / peek_deck / buy_from_others / opportunist ───────────────
# These require UI interaction and are tested manually on-device.
# Pure logic continuations can be exercised here once the dialog is bypassed.

func test_complete_recycle_refunds_gold_and_removes_card() -> void:
	var gold_card := _load_card("res://data/cards/card_004_gold_vein.tres")
	_add_to_hand(0, gold_card)
	var in_hand: CardData = PlayerManager.players[0].cards_in_hand.back() as CardData
	var cost: int = in_hand.gold_cost
	var gold_before: int = PlayerManager.players[0].gold
	_handler.complete_recycle(0, [in_hand])
	assert_eq(PlayerManager.players[0].gold, gold_before + cost)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 0)

func test_complete_mimic_applies_opponent_effect() -> void:
	# Give p1 a gold_per_turn card; mimic should grant p0 some gold
	var gold_turn := _load_card("res://data/cards/card_006_miners_luck.tres")
	_add_to_hand(1, gold_turn)
	var target: CardData = PlayerManager.players[1].cards_in_hand.back() as CardData
	var gold_before: int = PlayerManager.players[0].gold
	_handler.complete_mimic(0, target)
	assert_gt(PlayerManager.players[0].gold, gold_before)

func test_complete_buy_from_others_transfers_card() -> void:
	var iron_hide := _load_card("res://data/cards/card_002_iron_hide.tres")
	_add_to_hand(1, iron_hide)
	var in_hand: CardData = PlayerManager.players[1].cards_in_hand.back() as CardData
	PlayerManager.add_gold(0, 99)
	_handler.complete_buy_from_others(0, in_hand)
	assert_eq(PlayerManager.players[1].cards_in_hand.size(), 0)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 1)
