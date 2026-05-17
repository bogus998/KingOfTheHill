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

func _make_card(type: CardData.CardType, effect: CardEffectId.Id, cost: int = 1) -> CardData:
	var c := CardData.new()
	c.card_type = type
	c.effect = CardEffectFactory.create(effect)
	c.gem_cost = cost
	return c

# ── Gain gold ─────────────────────────────────────────────────────────────────

func test_gain_gold_1() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GAIN_GOLD_1)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 1)

func test_gain_gold_2() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GAIN_GOLD_2)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)

func test_gain_gold_3() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GAIN_GOLD_3)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 3)

func test_gain_gold_4() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GAIN_GOLD_4)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 4)

# ── Gain gems ─────────────────────────────────────────────────────────────────

func test_gain_gems_2() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GAIN_GEMS_2)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gems, 2)

func test_gain_gems_9() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GAIN_GEMS_9)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gems, 9)

# ── Heal ──────────────────────────────────────────────────────────────────────

func test_heal_2_restores_hp() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.HEAL_2)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].health, 7)

func test_heal_3_restores_hp() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.HEAL_3)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].health, 8)

func test_heal_3_capped_at_10() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.HEAL_3)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].health, 10)

# ── Damage ────────────────────────────────────────────────────────────────────

func test_damage_all_2() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.DAMAGE_ALL_2)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[1].health, 8)

func test_damage_all_including_self_3() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.DAMAGE_ALL_INCLUDING_SELF_3)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].health, 7)
	assert_eq(PlayerManager.players[1].health, 7)

# ── Combined effects ──────────────────────────────────────────────────────────

func test_gold_2_damage_all_3() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GOLD_2_DAMAGE_ALL_3)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[1].health, 7)

func test_gold_2_heal_3() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GOLD_2_HEAL_3)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[0].health, 8)

func test_gold_2_take_2_damage() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GOLD_2_TAKE_2_DAMAGE)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[0].health, 8)

func test_gold_4_take_3_damage() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GOLD_4_TAKE_3_DAMAGE)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 4)
	assert_eq(PlayerManager.players[0].health, 7)

func test_gold_5_take_4_damage() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GOLD_5_TAKE_4_DAMAGE)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 5)
	assert_eq(PlayerManager.players[0].health, 6)

# ── Steal gold ────────────────────────────────────────────────────────────────

func test_steal_gold_5_all_caps_at_available() -> void:
	PlayerManager.add_gold(1, 3)
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.STEAL_GOLD_5_ALL)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[1].gold, 0)

func test_steal_gold_5_all_limited_to_5() -> void:
	PlayerManager.add_gold(1, 8)
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.STEAL_GOLD_5_ALL)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[1].gold, 3)

func test_steal_gold_credits_source() -> void:
	PlayerManager.add_gold(0, 10)
	PlayerManager.add_gold(1, 8)
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.STEAL_GOLD_5_ALL)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 15)
	assert_eq(PlayerManager.players[1].gold, 3)

# ── War band ──────────────────────────────────────────────────────────────────

func test_war_band_empty_hand() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.WAR_BAND)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 0)
	assert_eq(PlayerManager.players[0].health, 10)

func test_war_band_with_two_cards() -> void:
	PlayerManager.add_card_to_hand(0, _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GEM_PER_TURN_1))
	PlayerManager.add_card_to_hand(0, _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GEM_PER_TURN_1))
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.WAR_BAND)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[0].health, 8)

# ── Gold + steal gems ─────────────────────────────────────────────────────────

func test_gold_2_steal_gems() -> void:
	PlayerManager.add_gems(1, 6)
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GOLD_2_STEAL_GEMS)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[0].gems, 3)  # source receives stolen gems
	assert_eq(PlayerManager.players[1].gems, 3)  # 6 / 2 = 3 lost

func test_gold_2_steal_gems_rounds_down() -> void:
	PlayerManager.add_gems(1, 5)
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GOLD_2_STEAL_GEMS)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gems, 2)  # source receives 2 stolen gems
	assert_eq(PlayerManager.players[1].gems, 3)  # 5 / 2 = 2 lost → 3 remain

# ── Permanent turn-start passives ─────────────────────────────────────────────

func test_gem_per_turn_1_passive_fires_on_turn_start() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GEM_PER_TURN_1)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[0].gems, 1)

func test_passive_damage_1_per_turn() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.PASSIVE_DAMAGE_1_PER_TURN)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[1].health, 9)

func test_vault_bonus_gold_2_only_in_vault() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.VAULT_BONUS_GOLD_2)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[0].gold, 0)  # Not in vault, no bonus

func test_vault_bonus_gold_2_in_vault() -> void:
	PlayerManager.set_position(0, PlayerData.PlayerPosition.AT_VAULT)
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.VAULT_BONUS_GOLD_2)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[0].gold, 2)

# ── Permanent turn-end passives ───────────────────────────────────────────────

func test_underdog_gold_fires_when_fewest() -> void:
	PlayerManager.add_gold(1, 5)
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.UNDERDOG_GOLD)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 1)

func test_underdog_gold_no_bonus_when_equal_gold() -> void:
	# Both have same gold — tied for fewest, both qualify
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.UNDERDOG_GOLD)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 1)  # 0 == 0, so qualifies

func test_underdog_gold_no_bonus_when_ahead() -> void:
	PlayerManager.add_gold(0, 5)
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.UNDERDOG_GOLD)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 5)  # No bonus

func test_gem_if_empty_fires_when_zero_gems() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GEM_IF_EMPTY)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gems, 1)

func test_gem_if_empty_no_bonus_when_has_gems() -> void:
	PlayerManager.add_gems(0, 3)
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GEM_IF_EMPTY)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gems, 3)

func test_gold_per_6gems_grants_per_6() -> void:
	PlayerManager.add_gems(0, 13)
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GOLD_PER_6GEMS)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 2)  # 13 / 6 = 2

func test_gold_per_6gems_no_bonus_below_6() -> void:
	PlayerManager.add_gems(0, 5)
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GOLD_PER_6GEMS)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[0].gold, 0)

# ── Purchase-triggered ────────────────────────────────────────────────────────

func test_gold_on_purchase_triggers_on_any_buy() -> void:
	var scribe := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GOLD_ON_PURCHASE)
	PlayerManager.add_card_to_hand(0, scribe)
	# Simulate purchasing a ONE_TIME card
	var other := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GAIN_GOLD_1)
	CardShop.card_purchased.emit(0, other)
	assert_eq(PlayerManager.players[0].gold, 2)  # +1 gain_gold_1 + 1 gold_on_purchase

func test_gold_on_purchase_triggers_when_buying_itself() -> void:
	# Buying Guild Scribe gives +1 gold from itself
	var scribe := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GOLD_ON_PURCHASE)
	PlayerManager.add_card_to_hand(0, scribe)  # Simulate shop adding it to hand
	CardShop.card_purchased.emit(0, scribe)
	assert_eq(PlayerManager.players[0].gold, 1)

# ── ONE_TIME and PERMANENT hand behavior ──────────────────────────────────────

func test_one_time_card_removed_from_hand_after_apply() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GAIN_GOLD_1)
	PlayerManager.add_card_to_hand(0, card)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 0)

func test_permanent_card_stays_in_hand_after_passive() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GEM_PER_TURN_1)
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
