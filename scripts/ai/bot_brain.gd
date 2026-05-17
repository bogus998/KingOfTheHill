class_name BotBrain
extends RefCounted

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

# Returns the die index to set to ONE for Die Picker / Wildcard (lowest-value die)
func decide_die_to_set(faces: Array) -> int:
	var lowest_idx := 0
	var lowest_val := 999
	for i in faces.size():
		var v: int = faces[i] as int
		if v < lowest_val:
			lowest_val = v
			lowest_idx = i
	return lowest_idx

# Returns the face to pick for Flexible Tactics (match the most frequent face)
func decide_flexible_tactics_face(faces: Array) -> DiceResolver.DieFace:
	var counts := {}
	for f in faces:
		counts[f] = counts.get(f, 0) + 1
	var best_face: DiceResolver.DieFace = DiceResolver.DieFace.GEM
	var best_count := 0
	for f in counts:
		if counts[f] > best_count:
			best_count = counts[f]
			best_face = f
	return best_face
