extends Node

func decide_holds(faces: Array, player_data: PlayerData) -> Array[bool]:
	var holds: Array[bool] = []
	holds.resize(faces.size())

	var counts: Dictionary = {}
	for f in faces:
		counts[f] = counts.get(f, 0) + 1

	for i in faces.size():
		var f = faces[i]
		match f:
			DiceResolver.DieFace.HEART:
				holds[i] = player_data.position == PlayerData.PlayerPosition.OUTSIDE \
						and player_data.health < 6
			DiceResolver.DieFace.CLAW:
				holds[i] = player_data.position == PlayerData.PlayerPosition.AT_VAULT
			DiceResolver.DieFace.GEM:
				holds[i] = true
			_:
				var count: int = counts.get(f, 0)
				holds[i] = count >= 3 or (count >= 2 and player_data.gold < 10)

	return holds

func decide_buy(visible_cards: Array, gems: int) -> int:
	var best_idx := -1
	var best_cost := 999
	for i in visible_cards.size():
		var card: CardData = visible_cards[i]
		if card.gem_cost <= gems and card.gem_cost < best_cost:
			best_cost = card.gem_cost
			best_idx = i
	return best_idx

func decide_flee(player_data: PlayerData) -> bool:
	return player_data.health < 4

func get_thinking_delay() -> float:
	return randf_range(0.8, 1.5)
