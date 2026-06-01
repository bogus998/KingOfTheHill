extends GutTest
## Round-trip coverage for GameStateSerializer: snapshot() -> mutate -> apply()
## must restore each authoritative manager exactly. Runs in single-player (the
## serializer is transport-agnostic).

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})

func after_each() -> void:
	EnvironmentManager.active_card = null
	EnvironmentManager.pending_card = null

# ── Players ───────────────────────────────────────────────────────────────────

func test_player_fields_round_trip() -> void:
	var p := PlayerManager.players[0]
	p.health = 7
	p.gold = 13
	p.gems = 4
	p.position = PlayerData.PlayerPosition.AT_VAULT
	p.poison_stacks = 2
	p.damage_reduction = 1
	p.is_eliminated = false

	var snap := GameStateSerializer.snapshot()
	p.health = 1
	p.gold = 0
	p.gems = 0
	p.position = PlayerData.PlayerPosition.OUTSIDE
	p.poison_stacks = 0
	p.damage_reduction = 0
	GameStateSerializer.apply(snap)

	var r := PlayerManager.players[0]
	assert_eq(r.health, 7)
	assert_eq(r.gold, 13)
	assert_eq(r.gems, 4)
	assert_eq(r.position, PlayerData.PlayerPosition.AT_VAULT)
	assert_eq(r.poison_stacks, 2)
	assert_eq(r.damage_reduction, 1)

func test_player_count_and_names_round_trip() -> void:
	var snap := GameStateSerializer.snapshot()
	PlayerManager.players.clear()
	GameStateSerializer.apply(snap)
	assert_eq(PlayerManager.players.size(), 2)
	assert_eq(PlayerManager.players[0].player_name, "Thorin")
	assert_eq(PlayerManager.players[1].player_name, "Gimli")

func test_cards_in_hand_round_trip() -> void:
	var src := CardCatalog.load_all_cards()[0]
	PlayerManager.add_card_to_hand(0, src)
	PlayerManager.players[0].cards_in_hand[0].charges = 3
	var card_name: String = PlayerManager.players[0].cards_in_hand[0].card_name

	var snap := GameStateSerializer.snapshot()
	PlayerManager.players[0].cards_in_hand.clear()
	GameStateSerializer.apply(snap)

	var hand := PlayerManager.players[0].cards_in_hand
	assert_eq(hand.size(), 1)
	assert_eq(hand[0].card_name, card_name)
	assert_eq(hand[0].charges, 3, "mutable charge count survives round-trip")

# ── Turn ──────────────────────────────────────────────────────────────────────

func test_turn_round_trip() -> void:
	TurnManager.current_player_index = 1
	TurnManager.round_number = 3
	TurnManager.roll_count = 2
	TurnManager.current_phase = TurnManager.TurnPhase.BUY_CARDS

	var snap := GameStateSerializer.snapshot()
	TurnManager.current_player_index = 0
	TurnManager.round_number = 1
	TurnManager.roll_count = 0
	TurnManager.current_phase = TurnManager.TurnPhase.DICE_ROLL
	GameStateSerializer.apply(snap)

	assert_eq(TurnManager.current_player_index, 1)
	assert_eq(TurnManager.round_number, 3)
	assert_eq(TurnManager.roll_count, 2)
	assert_eq(TurnManager.current_phase, TurnManager.TurnPhase.BUY_CARDS)

# ── Shop ──────────────────────────────────────────────────────────────────────

func test_shop_visible_cards_round_trip() -> void:
	var names: Array = []
	for c in CardShop.visible_cards:
		names.append(c.card_name)
	assert_gt(names.size(), 0, "shop should have visible cards after start_game")

	var snap := GameStateSerializer.snapshot()
	CardShop.visible_cards.clear()
	GameStateSerializer.apply(snap)

	assert_eq(CardShop.visible_cards.size(), names.size())
	for i in names.size():
		assert_eq(CardShop.visible_cards[i].card_name, names[i])

# ── Dragon ────────────────────────────────────────────────────────────────────

func test_dragon_rage_round_trip() -> void:
	DragonManager.restore_state(6, 9, 2, true)
	var snap := GameStateSerializer.snapshot()
	DragonManager.restore_state(0, 5, 0, false)
	GameStateSerializer.apply(snap)

	assert_eq(DragonManager.rage, 6)
	assert_eq(DragonManager.rage_threshold, 9)
	assert_eq(DragonManager.awakening_count, 2)
	assert_true(DragonManager.is_awakening_pending)

# ── Environment ───────────────────────────────────────────────────────────────

func test_environment_round_trip() -> void:
	var deck := EnvironmentDeck.load_all()
	if deck.is_empty():
		pass_test("no environment cards on disk to test")
		return
	EnvironmentManager.active_card = deck[0]
	var card_name: String = deck[0].card_name

	var snap := GameStateSerializer.snapshot()
	EnvironmentManager.active_card = null
	GameStateSerializer.apply(snap)

	assert_not_null(EnvironmentManager.active_card)
	assert_eq(EnvironmentManager.active_card.card_name, card_name)

func test_environment_empty_round_trip() -> void:
	EnvironmentManager.active_card = null
	EnvironmentManager.pending_card = null
	var snap := GameStateSerializer.snapshot()
	GameStateSerializer.apply(snap)
	assert_null(EnvironmentManager.active_card)
	assert_null(EnvironmentManager.pending_card)

# ── Client receive path (apply + refresh fan-out) ─────────────────────────────

## NetworkManager._receive_snapshot is the client entry point: it must rebuild the
## managers from the snapshot AND notify every node in REFRESH_GROUP via call_group.
func test_receive_snapshot_applies_and_refreshes_group() -> void:
	var spy := _RefreshSpy.new()
	add_child_autofree(spy)
	spy.add_to_group(NetworkManager.REFRESH_GROUP)

	PlayerManager.players[0].health = 5
	var snap := GameStateSerializer.snapshot()
	PlayerManager.players[0].health = 99  # corrupt live state

	NetworkManager._receive_snapshot(snap)

	assert_eq(PlayerManager.players[0].health, 5, "snapshot was applied to managers")
	assert_eq(spy.refresh_calls, 1, "refresh() fanned out to the group via call_group")

## Stub view that records how many times the refreshable contract was invoked.
class _RefreshSpy extends Node:
	var refresh_calls: int = 0
	func refresh() -> void:
		refresh_calls += 1
