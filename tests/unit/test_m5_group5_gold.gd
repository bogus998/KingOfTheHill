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
	c.gold_cost = cost
	return c

func _give_discount_card(player_idx: int) -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GOLD_DISCOUNT_1)
	PlayerManager.add_card_to_hand(player_idx, card)

# ── gold_discount_1 ────────────────────────────────────────────────────────────

func test_gold_discount_purchase_deducts_one_less_gold() -> void:
	_give_discount_card(0)
	PlayerManager.players[0].gold = 10
	# Force a known-cost card into slot 0
	var target := CardData.new()
	target.card_type = CardData.CardType.PERMANENT
	target.effect = CardEffectFactory.create(CardEffectId.Id.NONE)
	target.gold_cost = 4
	CardShop.visible_cards[0] = target
	CardShop.purchase(0, 0)
	assert_eq(PlayerManager.players[0].gold, 7)  # spent 3 instead of 4

func test_gold_discount_card_not_buyable_when_gold_below_discounted_cost() -> void:
	_give_discount_card(0)
	PlayerManager.players[0].gold = 2
	var target := CardData.new()
	target.card_type = CardData.CardType.PERMANENT
	target.effect = CardEffectFactory.create(CardEffectId.Id.NONE)
	target.gold_cost = 4
	CardShop.visible_cards[0] = target
	assert_false(CardShop.purchase(0, 0))  # needs 3, has 2

func test_gold_discount_two_copies_stack() -> void:
	_give_discount_card(0)
	_give_discount_card(0)
	PlayerManager.players[0].gold = 10
	var target := CardData.new()
	target.card_type = CardData.CardType.PERMANENT
	target.effect = CardEffectFactory.create(CardEffectId.Id.NONE)
	target.gold_cost = 4
	CardShop.visible_cards[0] = target
	CardShop.purchase(0, 0)
	assert_eq(PlayerManager.players[0].gold, 8)  # spent 2 instead of 4

func test_gold_discount_does_not_go_below_zero_cost() -> void:
	_give_discount_card(0)
	_give_discount_card(0)
	_give_discount_card(0)
	PlayerManager.players[0].gold = 0
	var target := CardData.new()
	target.card_type = CardData.CardType.PERMANENT
	target.effect = CardEffectFactory.create(CardEffectId.Id.NONE)
	target.gold_cost = 2
	CardShop.visible_cards[0] = target
	assert_true(CardShop.purchase(0, 0))  # effective cost = 0

# ── rapid_healing ──────────────────────────────────────────────────────────────

func test_rapid_healing_deducts_gold_and_heals() -> void:
	PlayerManager.players[0].gold = 5
	PlayerManager.players[0].health = 7
	_handler.apply_active_ability(CardEffectId.Id.RAPID_HEALING, 0)
	assert_eq(PlayerManager.players[0].gold, 3)
	assert_eq(PlayerManager.players[0].health, 8)

func test_rapid_healing_does_not_heal_when_gold_insufficient() -> void:
	PlayerManager.players[0].gold = 1
	var hp_before := PlayerManager.players[0].health
	_handler.apply_active_ability(CardEffectId.Id.RAPID_HEALING, 0)
	assert_eq(PlayerManager.players[0].health, hp_before)
	assert_eq(PlayerManager.players[0].gold, 1)

func test_rapid_healing_no_effect_at_vault() -> void:
	PlayerManager.players[0].gold = 5
	PlayerManager.players[0].health = 7
	PlayerManager.players[0].position = PlayerData.PlayerPosition.AT_VAULT
	_handler.apply_active_ability(CardEffectId.Id.RAPID_HEALING, 0)
	assert_eq(PlayerManager.players[0].gold, 3)   # gold spent
	assert_eq(PlayerManager.players[0].health, 7)  # no heal at vault

# ── nimble_dodge ───────────────────────────────────────────────────────────────

func test_nimble_dodge_sets_active_flag_and_spends_gold() -> void:
	PlayerManager.players[0].gold = 5
	_handler.apply_active_ability(CardEffectId.Id.NIMBLE_DODGE, 0)
	assert_true(PlayerManager.players[0].nimble_dodge_active)
	assert_eq(PlayerManager.players[0].gold, 4)

func test_nimble_dodge_does_not_activate_without_gold() -> void:
	PlayerManager.players[0].gold = 0
	_handler.apply_active_ability(CardEffectId.Id.NIMBLE_DODGE, 0)
	assert_false(PlayerManager.players[0].nimble_dodge_active)

func test_nimble_dodge_blocks_next_hit_by_one() -> void:
	PlayerManager.players[0].gold = 5
	_handler.apply_active_ability(CardEffectId.Id.NIMBLE_DODGE, 0)
	var hp_before := PlayerManager.players[0].health
	PlayerManager.apply_damage(0, 3)
	assert_eq(PlayerManager.players[0].health, hp_before - 2)

func test_nimble_dodge_flag_cleared_after_hit() -> void:
	PlayerManager.players[0].gold = 5
	_handler.apply_active_ability(CardEffectId.Id.NIMBLE_DODGE, 0)
	PlayerManager.apply_damage(0, 3)
	assert_false(PlayerManager.players[0].nimble_dodge_active)

func test_nimble_dodge_second_hit_not_blocked() -> void:
	PlayerManager.players[0].gold = 5
	_handler.apply_active_ability(CardEffectId.Id.NIMBLE_DODGE, 0)
	var hp_after_first_hit := PlayerManager.players[0].health - 2
	PlayerManager.apply_damage(0, 3)  # 3-1 = 2 damage
	var hp_before_second := PlayerManager.players[0].health
	PlayerManager.apply_damage(0, 3)  # no dodge, full 3 damage
	assert_eq(PlayerManager.players[0].health, hp_before_second - 3)

func test_nimble_dodge_cannot_be_used_twice_per_turn() -> void:
	PlayerManager.players[0].gold = 10
	_handler.apply_active_ability(CardEffectId.Id.NIMBLE_DODGE, 0)
	assert_true(PlayerManager.players[0].nimble_dodge_used_this_turn)
	_handler.apply_active_ability(CardEffectId.Id.NIMBLE_DODGE, 0)
	assert_eq(PlayerManager.players[0].gold, 9)  # only spent once

func test_nimble_dodge_negates_1_damage_hit() -> void:
	PlayerManager.players[0].gold = 5
	_handler.apply_active_ability(CardEffectId.Id.NIMBLE_DODGE, 0)
	var hp_before := PlayerManager.players[0].health
	PlayerManager.apply_damage(0, 1)
	assert_eq(PlayerManager.players[0].health, hp_before)  # 1-1 = 0, no damage

func test_nimble_dodge_flags_reset_on_turn_start() -> void:
	PlayerManager.players[0].nimble_dodge_active = true
	PlayerManager.players[0].nimble_dodge_used_this_turn = true
	_handler._on_turn_started(0)
	assert_false(PlayerManager.players[0].nimble_dodge_active)
	assert_false(PlayerManager.players[0].nimble_dodge_used_this_turn)

# ── slow_grinder ───────────────────────────────────────────────────────────────

func test_slow_grinder_converts_gold_to_gem() -> void:
	PlayerManager.players[0].gold = 5
	PlayerManager.players[0].gems = 0
	_handler.apply_active_ability(CardEffectId.Id.SLOW_GRINDER, 0)
	assert_eq(PlayerManager.players[0].gold, 2)
	assert_eq(PlayerManager.players[0].gems, 1)

func test_slow_grinder_no_conversion_when_gold_insufficient() -> void:
	PlayerManager.players[0].gold = 2
	var gems_before := PlayerManager.players[0].gems
	_handler.apply_active_ability(CardEffectId.Id.SLOW_GRINDER, 0)
	assert_eq(PlayerManager.players[0].gems, gems_before)
	assert_eq(PlayerManager.players[0].gold, 2)

func test_slow_grinder_can_be_used_multiple_times() -> void:
	PlayerManager.players[0].gold = 9
	PlayerManager.players[0].gems = 0
	_handler.apply_active_ability(CardEffectId.Id.SLOW_GRINDER, 0)
	_handler.apply_active_ability(CardEffectId.Id.SLOW_GRINDER, 0)
	_handler.apply_active_ability(CardEffectId.Id.SLOW_GRINDER, 0)
	assert_eq(PlayerManager.players[0].gold, 0)
	assert_eq(PlayerManager.players[0].gems, 3)

# ── paid_healing — deferred (requires mid-RESOLUTION device pass) ──────────────
# TODO: implement after PassDeviceScreen supports mid-phase interrupts
