extends GutTest

var _handler: CardEffectHandler = null

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})
	_handler = CardEffectHandler.new()
	CardShop.card_purchased.connect(_handler._on_card_purchased)
	TurnManager.turn_started.connect(_handler._on_turn_started)

func after_each() -> void:
	if CardShop.card_purchased.is_connected(_handler._on_card_purchased):
		CardShop.card_purchased.disconnect(_handler._on_card_purchased)
	if TurnManager.turn_started.is_connected(_handler._on_turn_started):
		TurnManager.turn_started.disconnect(_handler._on_turn_started)

func _make_card(type: CardData.CardType, effect: String, cost: int = 1) -> CardData:
	var c := CardData.new()
	c.card_type = type
	c.effect_id = effect
	c.gem_cost = cost
	return c

# ── Immediate effects ─────────────────────────────────────────────────────────

func test_gain_gold_1() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gain_gold_1")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gold, 1)

func test_heal_3_restores_hp() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.ONE_TIME, "heal_3")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].health, 8)

func test_heal_3_capped_at_10() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "heal_3")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].health, 10)

func test_gain_gems_2() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "gain_gems_2")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].gems, 2)

func test_damage_all_2() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, "damage_all_2")
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[1].health, 8)

# ── Passive effects ───────────────────────────────────────────────────────────

func test_gem_per_turn_1_passive_fires_on_turn_start() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, "gem_per_turn_1")
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_started.emit(0)
	assert_eq(PlayerManager.players[0].gems, 1)

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
	while CardShop.visible_cards.size() > 0 and bought < 20:
		CardShop.purchase(0, 0)
		bought += 1
	assert_eq(CardShop.visible_cards.size(), 0)
