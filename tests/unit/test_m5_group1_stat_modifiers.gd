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

# ── Group 1: Static stat modifiers ───────────────────────────────────────────

func test_damage_reduction_1_reduces_incoming_damage() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.DAMAGE_REDUCTION_1)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	assert_eq(PlayerManager.players[0].damage_reduction, 1)
	PlayerManager.apply_damage(0, 3)
	assert_eq(PlayerManager.players[0].health, 8)  # 10 - (3-1) = 8

func test_damage_reduction_1_floors_at_zero_damage() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.DAMAGE_REDUCTION_1)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	PlayerManager.apply_damage(0, 1)
	assert_eq(PlayerManager.players[0].health, 10)  # max(0, 1-1) = 0 damage

func test_health_cap_plus_2_increases_max_and_heals() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.HEALTH_CAP_PLUS_2)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	assert_eq(PlayerManager.players[0].max_health, 12)
	assert_eq(PlayerManager.players[0].health, 7)  # 5 + 2 heal

func test_health_cap_plus_2_allows_heal_above_10() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.HEALTH_CAP_PLUS_2)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	assert_eq(PlayerManager.players[0].health, 12)  # min(12, 10+2) = 12

func test_regen_bonus_adds_extra_to_each_heal() -> void:
	PlayerManager.apply_damage(0, 5)
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.REGEN_BONUS)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	assert_eq(PlayerManager.players[0].heal_bonus, 1)
	PlayerManager.apply_heal(0, 2)
	assert_eq(PlayerManager.players[0].health, 8)  # 5 + 2 + 1 bonus

func test_gem_bonus_on_gain_adds_extra_gem() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GEM_BONUS_ON_GAIN)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	assert_eq(PlayerManager.players[0].gem_gain_bonus, 1)
	PlayerManager.add_gems(0, 3)
	assert_eq(PlayerManager.players[0].gems, 4)  # 3 + 1 bonus
