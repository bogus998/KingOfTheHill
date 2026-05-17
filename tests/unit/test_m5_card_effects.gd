extends GutTest

var _handler: CardEffectHandler = null

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})
	TurnManager._repeat_turn_pending = false
	TurnManager.is_repeated_turn = false
	_handler = CardEffectHandler.new()
	CardShop.card_purchased.connect(_handler._on_card_purchased)
	TurnManager.turn_started.connect(_handler._on_turn_started)
	TurnManager.turn_ended.connect(_handler._on_turn_ended)
	PlayerManager.damage_applied.connect(_handler._on_damage_applied)
	PlayerManager.player_eliminated.connect(_handler._on_player_eliminated)
	PlayerManager.position_changed.connect(_handler._on_position_changed)

func after_each() -> void:
	if CardShop.card_purchased.is_connected(_handler._on_card_purchased):
		CardShop.card_purchased.disconnect(_handler._on_card_purchased)
	if TurnManager.turn_started.is_connected(_handler._on_turn_started):
		TurnManager.turn_started.disconnect(_handler._on_turn_started)
	if TurnManager.turn_ended.is_connected(_handler._on_turn_ended):
		TurnManager.turn_ended.disconnect(_handler._on_turn_ended)
	if PlayerManager.damage_applied.is_connected(_handler._on_damage_applied):
		PlayerManager.damage_applied.disconnect(_handler._on_damage_applied)
	if PlayerManager.player_eliminated.is_connected(_handler._on_player_eliminated):
		PlayerManager.player_eliminated.disconnect(_handler._on_player_eliminated)
	if PlayerManager.position_changed.is_connected(_handler._on_position_changed):
		PlayerManager.position_changed.disconnect(_handler._on_position_changed)

func _make_card(type: CardData.CardType, effect: String, cost: int = 1) -> CardData:
	var c := CardData.new()
	c.card_type = type
	c.effect_id = effect
	c.gem_cost = cost
	return c

# ── Gain gold ─────────────────────────────────────────────────────────────────

func test_gain_gold_1() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gain_gold_1")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 1)

func test_gain_gold_2() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gain_gold_2")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)

func test_gain_gold_3() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gain_gold_3")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 3)

func test_gain_gold_4() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gain_gold_4")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 4)

# ── Gain gems ─────────────────────────────────────────────────────────────────

func test_gain_gems_2() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gain_gems_2")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gems, 2)

func test_gain_gems_9() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gain_gems_9")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gems, 9)

# ── Heal ──────────────────────────────────────────────────────────────────────

func test_heal_2_restores_hp() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.ONE_TIME, "heal_2")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].health, 7)

func test_heal_3_restores_hp() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.ONE_TIME, "heal_3")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].health, 8)

func test_heal_3_capped_at_10() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "heal_3")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].health, 10)

# ── Damage ────────────────────────────────────────────────────────────────────

func test_damage_all_2() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "damage_all_2")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[1].health, 8)

func test_damage_all_including_self_3() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "damage_all_including_self_3")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].health, 7)
	assert_eq(PlayerManager.players[1].health, 7)

# ── Combined effects ──────────────────────────────────────────────────────────

func test_gold_2_damage_all_3() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gold_2_damage_all_3")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[1].health, 7)

func test_gold_2_heal_3() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.ONE_TIME, "gold_2_heal_3")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[0].health, 8)

func test_gold_2_take_2_damage() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gold_2_take_2_damage")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[0].health, 8)

func test_gold_4_take_3_damage() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gold_4_take_3_damage")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 4)
	assert_eq(PlayerManager.players[0].health, 7)

func test_gold_5_take_4_damage() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gold_5_take_4_damage")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 5)
	assert_eq(PlayerManager.players[0].health, 6)

# ── Steal gold ────────────────────────────────────────────────────────────────

func test_steal_gold_5_all_caps_at_available() -> void:
	PlayerManager.add_gold(1, 3)
	var card := _make_card(CardData.CardType.ONE_TIME, "steal_gold_5_all")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[1].gold, 0)

func test_steal_gold_5_all_limited_to_5() -> void:
	PlayerManager.add_gold(1, 8)
	var card := _make_card(CardData.CardType.ONE_TIME, "steal_gold_5_all")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[1].gold, 3)

func test_steal_gold_credits_source() -> void:
	PlayerManager.add_gold(0, 10)
	PlayerManager.add_gold(1, 8)
	var card := _make_card(CardData.CardType.ONE_TIME, "steal_gold_5_all")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 15)
	assert_eq(PlayerManager.players[1].gold, 3)

# ── War band ──────────────────────────────────────────────────────────────────

func test_war_band_empty_hand() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "war_band")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 0)
	assert_eq(PlayerManager.players[0].health, 10)

func test_war_band_with_two_cards() -> void:
	PlayerManager.add_card_to_hand(0, _make_card(CardData.CardType.PERMANENT, "gem_per_turn_1"))
	PlayerManager.add_card_to_hand(0, _make_card(CardData.CardType.PERMANENT, "gem_per_turn_1"))
	var card := _make_card(CardData.CardType.ONE_TIME, "war_band")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[0].health, 8)

# ── Gold + steal gems ─────────────────────────────────────────────────────────

func test_gold_2_steal_gems() -> void:
	PlayerManager.add_gems(1, 6)
	var card := _make_card(CardData.CardType.ONE_TIME, "gold_2_steal_gems")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[0].gems, 3)  # source receives stolen gems
	assert_eq(PlayerManager.players[1].gems, 3)  # 6 / 2 = 3 lost

func test_gold_2_steal_gems_rounds_down() -> void:
	PlayerManager.add_gems(1, 5)
	var card := _make_card(CardData.CardType.ONE_TIME, "gold_2_steal_gems")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gems, 2)  # source receives 2 stolen gems
	assert_eq(PlayerManager.players[1].gems, 3)  # 5 / 2 = 2 lost → 3 remain

# ── Permanent turn-start passives ─────────────────────────────────────────────

func test_gem_per_turn_1_passive_fires_on_turn_start() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gem_per_turn_1")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[0].gems, 1)

func test_passive_damage_1_per_turn() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "passive_damage_1_per_turn")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[1].health, 9)

func test_vault_bonus_gold_2_only_in_vault() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "vault_bonus_gold_2")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[0].gold, 0)  # Not in vault, no bonus

func test_vault_bonus_gold_2_in_vault() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	var card := _make_card(CardData.CardType.PERMANENT, "vault_bonus_gold_2")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[0].gold, 2)

# ── Permanent turn-end passives ───────────────────────────────────────────────

func test_underdog_gold_fires_when_fewest() -> void:
	PlayerManager.add_gold(1, 5)
	var card := _make_card(CardData.CardType.PERMANENT, "underdog_gold")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 1)

func test_underdog_gold_no_bonus_when_equal_gold() -> void:
	# Both have same gold — tied for fewest, both qualify
	var card := _make_card(CardData.CardType.PERMANENT, "underdog_gold")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 1)  # 0 == 0, so qualifies

func test_underdog_gold_no_bonus_when_ahead() -> void:
	PlayerManager.add_gold(0, 5)
	var card := _make_card(CardData.CardType.PERMANENT, "underdog_gold")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 5)  # No bonus

func test_gem_if_empty_fires_when_zero_gems() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gem_if_empty")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gems, 1)

func test_gem_if_empty_no_bonus_when_has_gems() -> void:
	PlayerManager.add_gems(0, 3)
	var card := _make_card(CardData.CardType.PERMANENT, "gem_if_empty")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gems, 3)

func test_gold_per_6gems_grants_per_6() -> void:
	PlayerManager.add_gems(0, 13)
	var card := _make_card(CardData.CardType.PERMANENT, "gold_per_6gems")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 2)  # 13 / 6 = 2

func test_gold_per_6gems_no_bonus_below_6() -> void:
	PlayerManager.add_gems(0, 5)
	var card := _make_card(CardData.CardType.PERMANENT, "gold_per_6gems")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 0)

# ── Purchase-triggered ────────────────────────────────────────────────────────

func test_gold_on_purchase_triggers_on_any_buy() -> void:
	var scribe := _make_card(CardData.CardType.PERMANENT, "gold_on_purchase")
	PlayerManager.add_card_to_hand(0, scribe)
	# Simulate purchasing a ONE_TIME card
	var other := _make_card(CardData.CardType.ONE_TIME, "gain_gold_1")
	CardShop.card_purchased.emit(0, other)
	assert_eq(PlayerManager.players[0].gold, 2)  # +1 gain_gold_1 + 1 gold_on_purchase

func test_gold_on_purchase_triggers_when_buying_itself() -> void:
	# Buying Guild Scribe gives +1 gold from itself
	var scribe := _make_card(CardData.CardType.PERMANENT, "gold_on_purchase")
	PlayerManager.add_card_to_hand(0, scribe)  # Simulate shop adding it to hand
	CardShop.card_purchased.emit(0, scribe)
	assert_eq(PlayerManager.players[0].gold, 1)

# ── ONE_TIME and PERMANENT hand behavior ──────────────────────────────────────

func test_one_time_card_removed_from_hand_after_apply() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gain_gold_1")
	PlayerManager.add_card_to_hand(0, card)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 0)

func test_permanent_card_stays_in_hand_after_passive() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gem_per_turn_1")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 1)

# ── Shop stability ────────────────────────────────────────────────────────────

func test_shop_no_crash_when_deck_exhausted() -> void:
	PlayerManager.add_gems(0, 1000)
	var bought := 0
	while CardShop.visible_cards.size() > 0 and bought < 200:
		CardShop.purchase(0, 0)
		bought += 1
	assert_eq(CardShop.visible_cards.size(), 0)

# ── Group 1: Static stat modifiers ───────────────────────────────────────────

func test_damage_reduction_1_reduces_incoming_damage() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "damage_reduction_1")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	assert_eq(PlayerManager.players[0].damage_reduction, 1)
	PlayerManager.apply_damage(0, 3)
	assert_eq(PlayerManager.players[0].health, 8)  # 10 - (3-1) = 8

func test_damage_reduction_1_floors_at_zero_damage() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "damage_reduction_1")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	PlayerManager.apply_damage(0, 1)
	assert_eq(PlayerManager.players[0].health, 10)  # max(0, 1-1) = 0 damage

func test_health_cap_plus_2_increases_max_and_heals() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.PERMANENT, "health_cap_plus_2")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	assert_eq(PlayerManager.players[0].max_health, 12)
	assert_eq(PlayerManager.players[0].health, 7)  # 5 + 2 heal

func test_health_cap_plus_2_allows_heal_above_10() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "health_cap_plus_2")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	assert_eq(PlayerManager.players[0].health, 12)  # min(12, 10+2) = 12

func test_regen_bonus_adds_extra_to_each_heal() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.PERMANENT, "regen_bonus")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	assert_eq(PlayerManager.players[0].heal_bonus, 1)
	PlayerManager.apply_heal(0, 2)
	assert_eq(PlayerManager.players[0].health, 8)  # 5 + 2 + 1 bonus

func test_gem_bonus_on_gain_adds_extra_gem() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gem_bonus_on_gain")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	assert_eq(PlayerManager.players[0].gem_gain_bonus, 1)
	PlayerManager.add_gems(0, 3)
	assert_eq(PlayerManager.players[0].gems, 4)  # 3 + 1 bonus

# ── Group 2: Event-triggered passives ────────────────────────────────────────

func test_gold_on_kill_awards_3_gold_on_elimination() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gold_on_kill")
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.apply_damage(1, 10)
	assert_eq(PlayerManager.players[1].is_eliminated, true)
	assert_eq(PlayerManager.players[0].gold, 3)

func test_gold_2_enter_vault_awards_on_entry() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gold_2_enter_vault")
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	assert_eq(PlayerManager.players[0].gold, 2)

func test_gold_2_enter_vault_no_gold_on_leave() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gold_2_enter_vault")
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	PlayerManager.set_position(0, PlayerData.PlayerPosition.OUTSIDE)
	assert_eq(PlayerManager.players[0].gold, 2)  # Only the entry gold

func test_gem_on_heavy_damage_awards_gem_on_2plus_hit() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gem_on_heavy_damage")
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.apply_damage(0, 2, 1)
	assert_eq(PlayerManager.players[0].gems, 1)

func test_gem_on_heavy_damage_no_gem_on_1_damage() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gem_on_heavy_damage")
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.apply_damage(0, 1, 1)
	assert_eq(PlayerManager.players[0].gems, 0)

func test_gold_if_no_damage_awards_gold_when_idle() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gold_if_no_damage")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 1)

func test_gold_if_no_damage_no_gold_after_dealing_damage() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gold_if_no_damage")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	PlayerManager.apply_damage(1, 2, 0)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 0)

func test_heavy_strike_gold_awards_2_gold_on_3plus_damage() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "heavy_strike_gold")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	PlayerManager.apply_damage(1, 3, 0)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 2)

func test_heavy_strike_gold_no_award_below_3_damage() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "heavy_strike_gold")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	PlayerManager.apply_damage(1, 2, 0)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 0)

func test_reflective_1_damages_attacker() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "reflective_1")
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.apply_damage(0, 2, 1)
	assert_eq(PlayerManager.players[0].health, 8)
	assert_eq(PlayerManager.players[1].health, 9)  # Reflected 1

func test_reflective_1_no_self_reflection() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "reflective_1")
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.apply_damage(0, 2)  # No attacker
	assert_eq(PlayerManager.players[0].health, 8)
	assert_eq(PlayerManager.players[1].health, 10)  # No reflection without attacker

func test_life_drain_heals_attacker_on_damage() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.PERMANENT, "life_drain")
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.apply_damage(1, 2, 0)
	assert_eq(PlayerManager.players[0].health, 6)  # 5 + 1 drain

func test_vault_dweller_gold_per_turn_in_vault() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	var card := _make_card(CardData.CardType.PERMANENT, "vault_dweller")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[0].gold, 1)

func test_vault_dweller_no_gold_outside_vault() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "vault_dweller")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[0].gold, 0)

# ── Group 3: Per-turn modifier flags ─────────────────────────────────────────

func test_extra_die_increments_die_count_modifier() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "extra_die")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_turn_started(0)
	assert_eq(PlayerManager.players[0].die_count_modifier, 1)

func test_extra_die_stacks_with_two_copies() -> void:
	PlayerManager.add_card_to_hand(0, _make_card(CardData.CardType.PERMANENT, "extra_die"))
	PlayerManager.add_card_to_hand(0, _make_card(CardData.CardType.PERMANENT, "extra_die"))
	_handler._on_turn_started(0)
	assert_eq(PlayerManager.players[0].die_count_modifier, 2)

func test_bonus_reroll_1_sets_flag() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "bonus_reroll_1")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_turn_started(0)
	assert_true(PlayerManager.players[0].has_free_reroll_after_max)

func test_free_reroll_threes_sets_flag() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "free_reroll_threes")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_turn_started(0)
	assert_true(PlayerManager.players[0].free_reroll_threes)

func test_set_die_to_one_sets_flag() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "set_die_to_one")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_turn_started(0)
	assert_true(PlayerManager.players[0].can_set_die_before_roll)

func test_modifier_flags_reset_on_turn_start() -> void:
	var p := PlayerManager.players[0]
	p.die_count_modifier = 3
	p.extra_rerolls_available = 2
	p.has_free_reroll_after_max = true
	p.free_reroll_threes = true
	p.can_set_die_before_roll = true
	p.war_drums_triggered = true
	_handler._on_turn_started(0)
	assert_eq(p.die_count_modifier, 0)
	assert_eq(p.extra_rerolls_available, 0)
	assert_false(p.has_free_reroll_after_max)
	assert_false(p.free_reroll_threes)
	assert_false(p.can_set_die_before_roll)
	assert_false(p.war_drums_triggered)

# ── Group 3: ONE_TIME deferred — Wildcard ─────────────────────────────────────

func test_wildcard_die_sets_pending_flag_and_removes_card() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "wildcard_die")
	PlayerManager.add_card_to_hand(0, card)
	_handler.apply_immediate(card, 0)
	assert_true(PlayerManager.players[0].wildcard_pending)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 0)

# ── Group 3: Smoke Bomb charge system ─────────────────────────────────────────

func test_smoke_bomb_adds_extra_reroll_on_use() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "smoke_bomb")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	_handler.use_smoke_bomb_charge(card, 0)
	assert_eq(PlayerManager.players[0].extra_rerolls_available, 1)

func test_smoke_bomb_removes_from_hand_when_charges_depleted() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "smoke_bomb")
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	_handler.use_smoke_bomb_charge(card, 0)
	_handler.use_smoke_bomb_charge(card, 0)
	_handler.use_smoke_bomb_charge(card, 0)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 0)
	assert_eq(PlayerManager.players[0].extra_rerolls_available, 3)

# ── Group 3: on_roll_finalized — Perfect Roll ─────────────────────────────────

func test_all_faces_bonus_awards_9_gold_on_all_six_faces() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "all_faces_bonus")
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.TWO,  DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GEM,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gold, 9)

func test_all_faces_bonus_no_gold_when_missing_a_face() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "all_faces_bonus")
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,  DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GEM,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gold, 0)

# ── Group 3: on_roll_finalized — Combo Master ─────────────────────────────────

func test_combo_master_awards_2_gold_on_one_two_three() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "combo_master")
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.TWO,  DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GEM,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gold, 2)

func test_combo_master_no_gold_without_all_three_numbers() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "combo_master")
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,  DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GEM,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gold, 0)

# ── Group 3: on_roll_finalized — Treasure Seeker ─────────────────────────────

func test_triple_one_gold_bonus_2_awards_extra_gold() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "triple_one_gold_bonus_2")
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.TWO,  DiceResolver.DieFace.GEM,  DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gold, 2)

func test_triple_one_gold_bonus_2_no_gold_with_only_two_ones() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "triple_one_gold_bonus_2")
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,  DiceResolver.DieFace.TWO,
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.GEM, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gold, 0)

# ── Group 3: on_roll_finalized — Time Stopper ────────────────────────────────

func test_triple_one_extra_turn_sets_repeat_pending_and_guard() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "triple_one_extra_turn")
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.ONE, DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.TWO, DiceResolver.DieFace.GEM, DiceResolver.DieFace.HEART,
	])
	assert_true(PlayerManager.players[0].repeat_turn_used)
	assert_true(TurnManager._repeat_turn_pending)

func test_triple_one_extra_turn_blocked_when_repeat_already_used() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "triple_one_extra_turn")
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.players[0].repeat_turn_used = true
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.ONE, DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.TWO, DiceResolver.DieFace.GEM, DiceResolver.DieFace.HEART,
	])
	assert_false(TurnManager._repeat_turn_pending)

func test_repeat_turn_used_persists_through_repeated_turn() -> void:
	PlayerManager.players[0].repeat_turn_used = true
	TurnManager.is_repeated_turn = true
	_handler._on_turn_started(0)
	TurnManager.is_repeated_turn = false
	assert_true(PlayerManager.players[0].repeat_turn_used)

func test_repeat_turn_used_resets_on_normal_turn_start() -> void:
	PlayerManager.players[0].repeat_turn_used = true
	_handler._on_turn_started(0)
	assert_false(PlayerManager.players[0].repeat_turn_used)

# ── Group 3: on_roll_finalized — Toxic Blade ─────────────────────────────────

func test_triple_two_damage_2_damages_others() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "triple_two_damage_2")
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.TWO, DiceResolver.DieFace.TWO, DiceResolver.DieFace.TWO,
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.GEM, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[1].health, 8)

func test_triple_two_damage_2_no_damage_without_triple() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "triple_two_damage_2")
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.TWO, DiceResolver.DieFace.TWO, DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.GEM, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[1].health, 10)

# ── Group 3: on_roll_finalized + turn_ended — War Drums ──────────────────────

func test_war_drums_triggers_on_4_or_more_dice_gold() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "war_drums")
	PlayerManager.add_card_to_hand(0, card)
	# 4x THREE → 3 + (4-3) = 4 gold
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.GEM,   DiceResolver.DieFace.HEART,
	])
	assert_true(PlayerManager.players[0].war_drums_triggered)

func test_war_drums_no_trigger_below_4_gold() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "war_drums")
	PlayerManager.add_card_to_hand(0, card)
	# triple THREE → 3 gold
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.ONE,   DiceResolver.DieFace.GEM,   DiceResolver.DieFace.HEART,
	])
	assert_false(PlayerManager.players[0].war_drums_triggered)

func test_war_drums_debuffs_others_on_turn_ended() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "war_drums")
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.players[0].war_drums_triggered = true
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[1].pending_die_penalty, 1)
	assert_false(PlayerManager.players[0].war_drums_triggered)

func test_war_drums_no_debuff_when_not_triggered() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "war_drums")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[1].pending_die_penalty, 0)

# ── Group 3: Repeated turn — income passives skipped ─────────────────────────

func test_income_passive_skipped_on_repeated_turn() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gem_per_turn_1")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.is_repeated_turn = true
	_handler._on_turn_started(0)
	TurnManager.is_repeated_turn = false
	assert_eq(PlayerManager.players[0].gems, 0)

func test_damage_passive_skipped_on_repeated_turn() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "passive_damage_1_per_turn")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.is_repeated_turn = true
	_handler._on_turn_started(0)
	TurnManager.is_repeated_turn = false
	assert_eq(PlayerManager.players[1].health, 10)

func test_die_modifier_still_applies_on_repeated_turn() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "extra_die")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.is_repeated_turn = true
	_handler._on_turn_started(0)
	TurnManager.is_repeated_turn = false
	assert_eq(PlayerManager.players[0].die_count_modifier, 1)
