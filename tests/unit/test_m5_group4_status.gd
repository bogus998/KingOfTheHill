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

# ── Poison ─────────────────────────────────────────────────────────────────────

func test_plague_blade_gives_target_poison_on_damage() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.POISON)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_damage_applied(0, 1, 1)
	assert_eq(PlayerManager.players[1].poison_stacks, 1)

func test_plague_blade_does_not_poison_self() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.POISON)
	PlayerManager.add_card_to_hand(0, card)
	# attacker == target, handler early-returns
	_handler._on_damage_applied(0, 0, 1)
	assert_eq(PlayerManager.players[0].poison_stacks, 0)

func test_plague_blade_stacks_across_multiple_attacks() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.POISON)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_damage_applied(0, 1, 1)
	_handler._on_damage_applied(0, 1, 1)
	assert_eq(PlayerManager.players[1].poison_stacks, 2)

func test_poison_tick_damages_on_turn_end() -> void:
	PlayerManager.players[1].poison_stacks = 2
	var hp_before: int = PlayerManager.players[1].health
	_handler._on_turn_ended(1)
	assert_eq(PlayerManager.players[1].health, hp_before - 2)

func test_poison_stacks_persist_after_tick() -> void:
	PlayerManager.players[1].poison_stacks = 3
	_handler._on_turn_ended(1)
	assert_eq(PlayerManager.players[1].poison_stacks, 3)

func test_poison_zero_stacks_deals_no_damage() -> void:
	PlayerManager.players[1].poison_stacks = 0
	var hp_before: int = PlayerManager.players[1].health
	_handler._on_turn_ended(1)
	assert_eq(PlayerManager.players[1].health, hp_before)

func test_poison_can_eliminate_player() -> void:
	PlayerManager.players[1].health = 2
	PlayerManager.players[1].poison_stacks = 3
	_handler._on_turn_ended(1)
	assert_true(PlayerManager.players[1].is_eliminated)

# ── Gold Dodge ─────────────────────────────────────────────────────────────────

func test_gold_dodge_sets_flag_and_spends_gold() -> void:
	PlayerManager.players[0].gold = 5
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GOLD_DODGE)
	PlayerManager.add_card_to_hand(0, card)
	_handler.apply_immediate(card, 0)
	assert_true(PlayerManager.players[0].gold_dodge_active)
	assert_eq(PlayerManager.players[0].gold, 3)

func test_gold_dodge_does_not_activate_without_gold() -> void:
	PlayerManager.players[0].gold = 1
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.GOLD_DODGE)
	PlayerManager.add_card_to_hand(0, card)
	_handler.apply_immediate(card, 0)
	assert_false(PlayerManager.players[0].gold_dodge_active)

func test_gold_dodge_blocks_all_damage_this_turn() -> void:
	PlayerManager.players[0].gold_dodge_active = true
	var hp_before: int = PlayerManager.players[0].health
	PlayerManager.apply_damage(0, 3)
	PlayerManager.apply_damage(0, 2)
	assert_eq(PlayerManager.players[0].health, hp_before)

func test_gold_dodge_flag_cleared_on_turn_end() -> void:
	PlayerManager.players[0].gold_dodge_active = true
	_handler._on_turn_ended(0)
	assert_false(PlayerManager.players[0].gold_dodge_active)

func test_gold_dodge_does_not_block_poison_on_turn_end() -> void:
	PlayerManager.players[0].gold = 5
	PlayerManager.players[0].poison_stacks = 2
	PlayerManager.players[0].gold_dodge_active = true
	var hp_before: int = PlayerManager.players[0].health
	# Turn end — dodge clears AND poison ticks (dodge does not block poison)
	_handler._on_turn_ended(0)
	assert_false(PlayerManager.players[0].gold_dodge_active)
	assert_lt(PlayerManager.players[0].health, hp_before)

# ── Shrink ─────────────────────────────────────────────────────────────────────

func test_shrink_applies_on_damage_dealt_by_owner() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.SHRINK)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_damage_applied(0, 1, 2)
	assert_eq(PlayerManager.players[1].shrink_stacks, 1)

func test_shrink_does_not_apply_when_other_player_attacks() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.SHRINK)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_damage_applied(1, 0, 2)
	assert_eq(PlayerManager.players[0].shrink_stacks, 0)

func test_shrink_reduces_die_count_modifier_on_turn_start() -> void:
	PlayerManager.players[1].shrink_stacks = 2
	_handler._on_turn_started(1)
	assert_eq(PlayerManager.players[1].die_count_modifier, -2)

func test_shrink_stacks_decrement_on_turn_end() -> void:
	PlayerManager.players[1].shrink_stacks = 3
	_handler._on_turn_ended(1)
	assert_eq(PlayerManager.players[1].shrink_stacks, 2)

func test_shrink_stacks_do_not_go_below_zero() -> void:
	PlayerManager.players[1].shrink_stacks = 0
	_handler._on_turn_ended(1)
	assert_eq(PlayerManager.players[1].shrink_stacks, 0)

func test_shrink_modifier_returns_to_zero_once_stacks_expire() -> void:
	PlayerManager.players[1].shrink_stacks = 1
	_handler._on_turn_started(1)
	assert_eq(PlayerManager.players[1].die_count_modifier, -1)
	_handler._on_turn_ended(1)
	assert_eq(PlayerManager.players[1].shrink_stacks, 0)
	_handler._on_turn_started(1)
	assert_eq(PlayerManager.players[1].die_count_modifier, 0)

# ── Camouflage ─────────────────────────────────────────────────────────────────

func test_stone_skin_sets_camouflage_active_on_turn_start() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.CAMOUFLAGE)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_turn_started(0)
	assert_true(PlayerManager.players[0].camouflage_active)

func test_camouflage_cleared_on_turn_end() -> void:
	PlayerManager.players[0].camouflage_active = true
	_handler._on_turn_ended(0)
	assert_false(PlayerManager.players[0].camouflage_active)

func test_camouflage_damage_applied_signal_fires() -> void:
	PlayerManager.players[0].camouflage_active = true
	var signal_received := [false]
	PlayerManager.damage_applied.connect(func(_a, _t, _amt): signal_received[0] = true)
	PlayerManager.apply_damage(0, 3)
	assert_true(signal_received[0])
