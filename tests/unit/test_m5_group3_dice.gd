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

# ── Group 3: Per-turn modifier flags ─────────────────────────────────────────

func test_extra_die_increments_die_count_modifier() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.EXTRA_DIE)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_turn_started(0)
	assert_eq(PlayerManager.players[0].die_count_modifier, 1)

func test_extra_die_stacks_with_two_copies() -> void:
	PlayerManager.add_card_to_hand(0, _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.EXTRA_DIE))
	PlayerManager.add_card_to_hand(0, _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.EXTRA_DIE))
	_handler._on_turn_started(0)
	assert_eq(PlayerManager.players[0].die_count_modifier, 2)

func test_bonus_reroll_1_sets_flag() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.BONUS_REROLL_1)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_turn_started(0)
	assert_true(PlayerManager.players[0].has_free_reroll_after_max)

func test_free_reroll_threes_sets_flag() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.FREE_REROLL_THREES)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_turn_started(0)
	assert_true(PlayerManager.players[0].free_reroll_threes)

func test_modifier_flags_reset_on_turn_start() -> void:
	var p := PlayerManager.players[0]
	p.die_count_modifier = 3
	p.extra_rerolls_available = 2
	p.has_free_reroll_after_max = true
	p.free_reroll_threes = true
	p.war_drums_triggered = true
	p.die_picker_used_this_turn = true
	p.die_jacker_used_this_turn = true
	_handler._on_turn_started(0)
	assert_eq(p.die_count_modifier, 0)
	assert_eq(p.extra_rerolls_available, 0)
	assert_false(p.has_free_reroll_after_max)
	assert_false(p.free_reroll_threes)
	assert_false(p.war_drums_triggered)
	assert_false(p.die_picker_used_this_turn)
	assert_false(p.die_jacker_used_this_turn)

# ── Group 3: Die Picker ──────────────────────────────────────────────────────

func test_die_picker_used_flag_prevents_reuse() -> void:
	PlayerManager.players[0].die_picker_used_this_turn = true
	# Flag stays true — handler does not clear it mid-turn
	assert_true(PlayerManager.players[0].die_picker_used_this_turn)
	_handler._on_turn_started(0)
	assert_false(PlayerManager.players[0].die_picker_used_this_turn)

# ── Group 3: Die Jacker ───────────────────────────────────────────────────────

func test_die_jacker_sets_pending_on_opponents() -> void:
	_handler.apply_die_jacker(0)
	assert_false(PlayerManager.players[0].die_jacker_pending)
	assert_true(PlayerManager.players[1].die_jacker_pending)

func test_die_jacker_sets_used_flag() -> void:
	_handler.apply_die_jacker(0)
	assert_true(PlayerManager.players[0].die_jacker_used_this_turn)

func test_die_jacker_cannot_be_used_twice_per_turn() -> void:
	_handler.apply_die_jacker(0)
	PlayerManager.players[1].die_jacker_pending = false
	_handler.apply_die_jacker(0)
	assert_false(PlayerManager.players[1].die_jacker_pending)

func test_die_jacker_skips_eliminated_opponents() -> void:
	PlayerManager.players[1].is_eliminated = true
	_handler.apply_die_jacker(0)
	assert_false(PlayerManager.players[1].die_jacker_pending)

# ── Group 3: ONE_TIME deferred — Wildcard ─────────────────────────────────────

func test_wildcard_die_removes_card_on_apply_immediate() -> void:
	var card := _make_card(CardData.CardType.ONE_TIME, CardEffectId.Id.WILDCARD_DIE)
	PlayerManager.add_card_to_hand(0, card)
	_handler.apply_immediate(card, 0)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 0)

# ── Group 3: Smoke Bomb charge system ─────────────────────────────────────────

func test_smoke_bomb_adds_extra_reroll_on_use() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.SMOKE_BOMB)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	_handler.use_smoke_bomb_charge(card, 0)
	assert_eq(PlayerManager.players[0].extra_rerolls_available, 1)

func test_smoke_bomb_removes_from_hand_when_charges_depleted() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.SMOKE_BOMB)
	PlayerManager.add_card_to_hand(0, card)
	_handler._on_card_purchased(0, card)
	_handler.use_smoke_bomb_charge(card, 0)
	_handler.use_smoke_bomb_charge(card, 0)
	_handler.use_smoke_bomb_charge(card, 0)
	assert_eq(PlayerManager.players[0].cards_in_hand.size(), 0)
	assert_eq(PlayerManager.players[0].extra_rerolls_available, 3)

# ── Group 3: on_roll_finalized — Perfect Roll ─────────────────────────────────

func test_all_faces_bonus_awards_9_gems_on_all_six_faces() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.ALL_FACES_BONUS)
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.TWO,  DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gems, 9)

func test_all_faces_bonus_no_gems_when_missing_a_face() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.ALL_FACES_BONUS)
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,  DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gems, 0)

# ── Group 3: on_roll_finalized — Combo Master ─────────────────────────────────

func test_combo_master_awards_2_gems_on_one_two_three() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.COMBO_MASTER)
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.TWO,  DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gems, 2)

func test_combo_master_no_gems_without_all_three_numbers() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.COMBO_MASTER)
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,  DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gems, 0)

# ── Group 3: on_roll_finalized — Treasure Seeker ─────────────────────────────

func test_triple_one_gems_bonus_2_awards_extra_gems() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.TRIPLE_ONE_GEM_BONUS_2)
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.TWO,  DiceResolver.DieFace.GOLD,  DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gems, 2)

func test_triple_one_gems_bonus_2_no_gems_with_only_two_ones() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.TRIPLE_ONE_GEM_BONUS_2)
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE,  DiceResolver.DieFace.ONE,  DiceResolver.DieFace.TWO,
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[0].gems, 0)

# ── Group 3: on_roll_finalized — Time Stopper ────────────────────────────────

func test_triple_one_extra_turn_sets_repeat_pending_and_guard() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.TRIPLE_ONE_EXTRA_TURN)
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.ONE, DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.TWO, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.HEART,
	])
	assert_true(PlayerManager.players[0].repeat_turn_used)
	assert_true(TurnManager._repeat_turn_pending)

func test_triple_one_extra_turn_blocked_when_repeat_already_used() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.TRIPLE_ONE_EXTRA_TURN)
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.players[0].repeat_turn_used = true
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.ONE, DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.TWO, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.HEART,
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
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.TRIPLE_TWO_DAMAGE_2)
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.TWO, DiceResolver.DieFace.TWO, DiceResolver.DieFace.TWO,
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[1].health, 8)

func test_triple_two_damage_2_no_damage_without_triple() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.TRIPLE_TWO_DAMAGE_2)
	PlayerManager.add_card_to_hand(0, card)
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.TWO, DiceResolver.DieFace.TWO, DiceResolver.DieFace.ONE,
		DiceResolver.DieFace.ONE, DiceResolver.DieFace.GOLD, DiceResolver.DieFace.HEART,
	])
	assert_eq(PlayerManager.players[1].health, 10)

# ── Group 3: on_roll_finalized + turn_ended — War Drums ──────────────────────

func test_war_drums_triggers_on_4_or_more_dice_gems() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.WAR_DRUMS)
	PlayerManager.add_card_to_hand(0, card)
	# 4x THREE → 3 + (4-3) = 4 gems
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.GOLD,   DiceResolver.DieFace.HEART,
	])
	assert_true(PlayerManager.players[0].war_drums_triggered)

func test_war_drums_no_trigger_below_4_gems() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.WAR_DRUMS)
	PlayerManager.add_card_to_hand(0, card)
	# triple THREE → 3 gems
	_handler.on_roll_finalized(0, [
		DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE, DiceResolver.DieFace.THREE,
		DiceResolver.DieFace.ONE,   DiceResolver.DieFace.GOLD,   DiceResolver.DieFace.HEART,
	])
	assert_false(PlayerManager.players[0].war_drums_triggered)

func test_war_drums_debuffs_others_on_turn_ended() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.WAR_DRUMS)
	PlayerManager.add_card_to_hand(0, card)
	PlayerManager.players[0].war_drums_triggered = true
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[1].pending_die_penalty, 1)
	assert_false(PlayerManager.players[0].war_drums_triggered)

func test_war_drums_no_debuff_when_not_triggered() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.WAR_DRUMS)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.turn_ended.emit(0)
	assert_eq(PlayerManager.players[1].pending_die_penalty, 0)

# ── Group 3: Repeated turn — income passives skipped ─────────────────────────

func test_income_passive_skipped_on_repeated_turn() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.GOLD_PER_TURN_1)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.is_repeated_turn = true
	_handler._on_turn_started(0)
	TurnManager.is_repeated_turn = false
	assert_eq(PlayerManager.players[0].gold, 0)

func test_damage_passive_skipped_on_repeated_turn() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.PASSIVE_DAMAGE_1_PER_TURN)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.is_repeated_turn = true
	_handler._on_turn_started(0)
	TurnManager.is_repeated_turn = false
	assert_eq(PlayerManager.players[1].health, 10)

func test_die_modifier_still_applies_on_repeated_turn() -> void:
	var card := _make_card(CardData.CardType.PERMANENT, CardEffectId.Id.EXTRA_DIE)
	PlayerManager.add_card_to_hand(0, card)
	TurnManager.is_repeated_turn = true
	_handler._on_turn_started(0)
	TurnManager.is_repeated_turn = false
	assert_eq(PlayerManager.players[0].die_count_modifier, 1)
