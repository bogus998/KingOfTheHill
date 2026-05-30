extends Node

signal players_setup()
signal player_damaged(player_index: int, new_hp: int)
signal player_healed(player_index: int, new_hp: int)
signal player_eliminated(player_index: int)
signal gem_changed(player_index: int, new_gems: int)
signal gold_changed(player_index: int, new_gold: int)
signal position_changed(player_index: int, new_position: PlayerData.PlayerPosition)
signal card_hand_changed(player_index: int)
signal win_condition_met(winner_index: int, reason: String)
signal damage_applied(attacker_index: int, target_index: int, amount: int)
signal player_respawned(player_index: int)

var players: Array[PlayerData] = []

func setup(configs: Array[Dictionary]) -> void:
	players.clear()
	for cfg in configs:
		var p := PlayerData.new()
		p.player_name = cfg.get("name", "Player")
		p.is_bot = cfg.get("is_bot", false)
		players.append(p)
	players_setup.emit()

func apply_damage(player_index: int, amount: int, attacker_index: int = -1) -> void:
	var p := players[player_index]
	if p.is_eliminated:
		return
	if p.gold_dodge_active:
		damage_applied.emit(attacker_index, player_index, 0)
		return
	if p.nimble_dodge_active:
		p.nimble_dodge_active = false
		amount = max(0, amount - 1)
		if amount == 0:
			damage_applied.emit(attacker_index, player_index, 0)
			return
	if _has_camouflage(player_index):
		amount = _resolve_camouflage(amount)
	var actual: int = max(0, amount - p.damage_reduction)
	p.health = max(0, p.health - actual)
	player_damaged.emit(player_index, p.health)
	if actual > 0 and attacker_index >= 0 and attacker_index != player_index:
		players[attacker_index].damage_dealt_this_turn += actual
	damage_applied.emit(attacker_index, player_index, actual)
	if p.health == 0:
		_eliminate(player_index)
	check_win_conditions()

func _has_camouflage(player_index: int) -> bool:
	for card in players[player_index].cards_in_hand:
		if card.effect != null and card.effect.effect_id == CardEffectId.Id.CAMOUFLAGE:
			return true
	return false

func _resolve_camouflage(incoming: int) -> int:
	var remaining := incoming
	for _i in incoming:
		if randi() % 6 + 1 == DiceResolver.DieFace.HEART:
			remaining -= 1
	return max(0, remaining)

func apply_heal(player_index: int, amount: int) -> void:
	var p := players[player_index]
	if p.is_eliminated or p.position == PlayerData.PlayerPosition.AT_VAULT or amount <= 0:
		return
	p.health = min(p.max_health, p.health + amount + p.heal_bonus)
	player_healed.emit(player_index, p.health)

func add_gems(player_index: int, amount: int) -> void:
	var p := players[player_index]
	p.gems += amount
	gem_changed.emit(player_index, p.gems)
	check_win_conditions()

func add_gold(player_index: int, amount: int) -> void:
	var p := players[player_index]
	p.gold += amount + p.gold_gain_bonus
	gold_changed.emit(player_index, p.gold)

func spend_gold(player_index: int, amount: int) -> bool:
	var p := players[player_index]
	if p.gold < amount:
		return false
	p.gold -= amount
	gold_changed.emit(player_index, p.gold)
	return true

func set_position(player_index: int, pos: PlayerData.PlayerPosition) -> void:
	players[player_index].position = pos
	position_changed.emit(player_index, pos)

func get_vault_occupant() -> int:
	for i in players.size():
		if players[i].position == PlayerData.PlayerPosition.AT_VAULT and not players[i].is_eliminated:
			return i
	return -1

func add_card_to_hand(player_index: int, card: CardData) -> void:
	players[player_index].cards_in_hand.append(card.duplicate())
	card_hand_changed.emit(player_index)

func remove_card_from_hand(player_index: int, card: CardData) -> void:
	var hand := players[player_index].cards_in_hand
	if not hand.has(card):
		return
	hand.erase(card)
	card_hand_changed.emit(player_index)

func check_win_conditions() -> void:
	var alive := _alive_players()

	# Gem victory
	for i in players.size():
		if not players[i].is_eliminated and players[i].gems >= 20:
			win_condition_met.emit(i, "gems")
			return

	# Last standing
	if alive.size() == 1:
		win_condition_met.emit(alive[0], "elimination")
		return

	# Draw: all reach 0 HP in the same turn (all eliminated simultaneously)
	if alive.size() == 0:
		win_condition_met.emit(-1, "draw")

func _eliminate(player_index: int) -> void:
	if _check_revival(player_index):
		return
	players[player_index].is_eliminated = true
	player_eliminated.emit(player_index)

func _check_revival(player_index: int) -> bool:
	var p := players[player_index]
	# shield_bearer: keeps all other cards, only discards itself
	for card in p.cards_in_hand:
		if card.effect != null and card.effect.effect_id == CardEffectId.Id.SHIELD_BEARER:
			remove_card_from_hand(player_index, card)
			p.gems = 0
			gem_changed.emit(player_index, 0)
			p.health = p.max_health
			player_healed.emit(player_index, p.health)
			player_respawned.emit(player_index)
			return true
	# respawn: clears all cards on revival
	for card in p.cards_in_hand:
		if card.effect != null and card.effect.effect_id == CardEffectId.Id.RESPAWN:
			p.cards_in_hand.clear()
			card_hand_changed.emit(player_index)
			p.gems = 0
			gem_changed.emit(player_index, 0)
			p.health = p.max_health
			player_healed.emit(player_index, p.health)
			player_respawned.emit(player_index)
			return true
	return false

func _alive_players() -> Array[int]:
	var alive: Array[int] = []
	for i in players.size():
		if not players[i].is_eliminated:
			alive.append(i)
	return alive
