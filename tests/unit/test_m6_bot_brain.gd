extends GutTest

var _brain: BotBrain = null

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Bot",    "is_bot": true},
	]})
	_brain = BotBrain.new()

func _make_player(hp: int, pos: PlayerData.PlayerPosition, gold: int = 0) -> PlayerData:
	var p := PlayerData.new()
	p.health = hp
	p.position = pos
	p.gold = gold
	return p

# ── decide_holds ──────────────────────────────────────────────────────────────

func test_holds_hearts_when_low_hp_outside() -> void:
	var player := _make_player(5, PlayerData.PlayerPosition.OUTSIDE)
	var faces := [DiceResolver.DieFace.HEART, DiceResolver.DieFace.ONE,
			DiceResolver.DieFace.TWO, DiceResolver.DieFace.THREE,
			DiceResolver.DieFace.GEM, DiceResolver.DieFace.CLAW]
	var holds: Array[bool] = _brain.decide_holds(faces, player)
	assert_true(holds[0])

func test_does_not_hold_hearts_at_vault() -> void:
	var player := _make_player(5, PlayerData.PlayerPosition.AT_VAULT)
	var faces := [DiceResolver.DieFace.HEART, DiceResolver.DieFace.ONE,
			DiceResolver.DieFace.TWO, DiceResolver.DieFace.THREE,
			DiceResolver.DieFace.GEM, DiceResolver.DieFace.CLAW]
	var holds: Array[bool] = _brain.decide_holds(faces, player)
	assert_false(holds[0])

func test_holds_claws_at_vault_when_hp_low() -> void:
	var player := _make_player(4, PlayerData.PlayerPosition.AT_VAULT)
	var faces := [DiceResolver.DieFace.CLAW, DiceResolver.DieFace.ONE,
			DiceResolver.DieFace.TWO, DiceResolver.DieFace.THREE,
			DiceResolver.DieFace.GEM, DiceResolver.DieFace.HEART]
	var holds: Array[bool] = _brain.decide_holds(faces, player)
	assert_true(holds[0])

func test_holds_matching_numbers_when_gold_needed() -> void:
	var player := _make_player(10, PlayerData.PlayerPosition.OUTSIDE, 3)
	var faces := [DiceResolver.DieFace.TWO, DiceResolver.DieFace.TWO,
			DiceResolver.DieFace.THREE, DiceResolver.DieFace.GEM,
			DiceResolver.DieFace.HEART, DiceResolver.DieFace.CLAW]
	var holds: Array[bool] = _brain.decide_holds(faces, player)
	assert_true(holds[0])
	assert_true(holds[1])

# ── decide_buy ────────────────────────────────────────────────────────────────

func test_decide_buy_returns_cheapest_affordable() -> void:
	var cards: Array = []
	var c1 := CardData.new(); c1.gem_cost = 3; cards.append(c1)
	var c2 := CardData.new(); c2.gem_cost = 1; cards.append(c2)
	var c3 := CardData.new(); c3.gem_cost = 2; cards.append(c3)
	assert_eq(_brain.decide_buy(cards, 2), 1)

func test_decide_buy_returns_minus1_when_unaffordable() -> void:
	var cards: Array = []
	var c1 := CardData.new(); c1.gem_cost = 5; cards.append(c1)
	assert_eq(_brain.decide_buy(cards, 2), -1)

# ── decide_flee ───────────────────────────────────────────────────────────────

func test_decide_flee_true_when_hp_below_4() -> void:
	var player := _make_player(3, PlayerData.PlayerPosition.AT_VAULT)
	assert_true(_brain.decide_flee(player))

func test_decide_flee_false_when_hp_sufficient() -> void:
	var player := _make_player(6, PlayerData.PlayerPosition.AT_VAULT)
	assert_false(_brain.decide_flee(player))

# ── get_thinking_delay ────────────────────────────────────────────────────────

func test_thinking_delay_in_range() -> void:
	for _i in 20:
		var delay: float = _brain.get_thinking_delay()
		assert_true(delay >= 0.8 and delay <= 1.5)
