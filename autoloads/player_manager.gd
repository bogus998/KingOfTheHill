extends Node

signal player_damaged(player_index: int, new_hp: int)
signal player_healed(player_index: int, new_hp: int)
signal player_eliminated(player_index: int)
signal gold_changed(player_index: int, new_gold: int)
signal gem_changed(player_index: int, new_gems: int)
signal position_changed(player_index: int, new_position: PlayerData.PlayerPosition)
signal card_hand_changed(player_index: int)
signal win_condition_met(winner_index: int, reason: String)

const MAX_HEALTH := 10

var players: Array[PlayerData] = []

func setup(configs: Array[Dictionary]) -> void:
	players.clear()
	for cfg in configs:
		var p := PlayerData.new()
		p.player_name = cfg.get("name", "Player")
		p.is_bot = cfg.get("is_bot", false)
		players.append(p)

func apply_damage(player_index: int, amount: int) -> void:
	var p := players[player_index]
	if p.is_eliminated:
		return
	p.health = max(0, p.health - amount)
	emit_signal("player_damaged", player_index, p.health)
	if p.health == 0:
		_eliminate(player_index)
	check_win_conditions()

func apply_heal(player_index: int, amount: int) -> void:
	var p := players[player_index]
	if p.is_eliminated or p.position == PlayerData.PlayerPosition.AT_VAULT:
		return
	p.health = min(MAX_HEALTH, p.health + amount)
	emit_signal("player_healed", player_index, p.health)

func add_gold(player_index: int, amount: int) -> void:
	var p := players[player_index]
	p.gold += amount
	emit_signal("gold_changed", player_index, p.gold)
	check_win_conditions()

func add_gems(player_index: int, amount: int) -> void:
	var p := players[player_index]
	p.gems += amount
	emit_signal("gem_changed", player_index, p.gems)

func spend_gems(player_index: int, amount: int) -> bool:
	var p := players[player_index]
	if p.gems < amount:
		return false
	p.gems -= amount
	emit_signal("gem_changed", player_index, p.gems)
	return true

func set_position(player_index: int, pos: PlayerData.PlayerPosition) -> void:
	players[player_index].position = pos
	emit_signal("position_changed", player_index, pos)

func get_vault_occupant() -> int:
	for i in players.size():
		if players[i].position == PlayerData.PlayerPosition.AT_VAULT and not players[i].is_eliminated:
			return i
	return -1

func add_card_to_hand(player_index: int, card: CardData) -> void:
	players[player_index].cards_in_hand.append(card)
	emit_signal("card_hand_changed", player_index)

func remove_card_from_hand(player_index: int, card: CardData) -> void:
	players[player_index].cards_in_hand.erase(card)
	emit_signal("card_hand_changed", player_index)

func check_win_conditions() -> void:
	var alive := _alive_players()

	# Gold victory
	for i in players.size():
		if not players[i].is_eliminated and players[i].gold >= 20:
			emit_signal("win_condition_met", i, "gold")
			return

	# Last standing
	if alive.size() == 1:
		emit_signal("win_condition_met", alive[0], "elimination")
		return

	# Draw: all reach 0 HP in the same turn (all eliminated simultaneously)
	if alive.size() == 0:
		emit_signal("win_condition_met", -1, "draw")

func _eliminate(player_index: int) -> void:
	players[player_index].is_eliminated = true
	emit_signal("player_eliminated", player_index)

func _alive_players() -> Array[int]:
	var alive: Array[int] = []
	for i in players.size():
		if not players[i].is_eliminated:
			alive.append(i)
	return alive
