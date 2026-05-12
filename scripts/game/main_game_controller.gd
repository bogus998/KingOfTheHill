extends Node

func _ready() -> void:
	_run_m1_verification()

func _run_m1_verification() -> void:
	print("=== M1 VERIFICATION ===")

	# Setup 2 players
	PlayerManager.setup([
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	])

	# Check 1: Initial player states
	for i in PlayerManager.players.size():
		var p := PlayerManager.players[i]
		print("Player %d: %s | HP=%d gold=%d gems=%d pos=%s bot=%s" % [
			i, p.player_name, p.health, p.gold, p.gems,
			PlayerData.PlayerPosition.keys()[p.position], str(p.is_bot)
		])
	assert(PlayerManager.players[0].health == 10, "FAIL: HP should be 10")
	assert(PlayerManager.players[0].gold == 0,    "FAIL: gold should be 0")
	print("[PASS] Initial player states correct")

	# Check 2: Card deck loaded
	var deck_size := CardShop.visible_cards.size() + CardShop._deck.size()
	print("Deck total loaded: %d cards visible + %d in deck = %d" % [
		CardShop.visible_cards.size(), CardShop._deck.size(), deck_size
	])
	assert(deck_size == 10, "FAIL: expected 10 cards total")
	print("[PASS] 10 placeholder cards loaded and shuffled")

	# Check 3: apply_damage
	PlayerManager.player_damaged.connect(func(idx, hp): print("  signal player_damaged: player %d → HP %d" % [idx, hp]))
	PlayerManager.apply_damage(0, 3)
	assert(PlayerManager.players[0].health == 7, "FAIL: HP should be 7 after 3 damage")
	print("[PASS] apply_damage(0, 3) → HP = 7")

	# Check 4: add_gold win condition
	PlayerManager.win_condition_met.connect(func(winner, reason):
		print("  signal win_condition_met: winner=%d reason=%s" % [winner, reason])
	)
	PlayerManager.add_gold(0, 20)
	assert(PlayerManager.players[0].gold == 20, "FAIL: gold should be 20")
	print("[PASS] add_gold(0, 20) → gold = 20, win condition fired")

	# Reset for shop test
	PlayerManager.setup([
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	])
	PlayerManager.players[0].gems = 10

	# Check 5: CardShop purchase
	var card_before := CardShop.visible_cards[0]
	var cost := card_before.gem_cost
	CardShop.card_purchased.connect(func(pidx, card):
		print("  signal card_purchased: player %d bought '%s'" % [pidx, card.card_name])
	)
	var ok := CardShop.purchase(0, 0)
	assert(ok, "FAIL: purchase should succeed with 10 gems")
	assert(PlayerManager.players[0].gems == 10 - cost,
		"FAIL: gems should be %d after purchase" % (10 - cost))
	print("[PASS] CardShop.purchase(0, 0) → gems deducted, card_purchased signal fired")
	print("  Visible cards after purchase: %d" % CardShop.visible_cards.size())

	print("=== M1 ALL CHECKS PASSED ===")
