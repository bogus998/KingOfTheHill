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
