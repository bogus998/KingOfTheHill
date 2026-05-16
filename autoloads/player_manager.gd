extends Node

signal players_setup()
signal player_damaged(player_index: int, new_hp: int)
signal player_healed(player_index: int, new_hp: int)
signal player_eliminated(player_index: int)
signal gold_changed(player_index: int, new_gold: int)
signal gem_changed(player_index: int, new_gems: int)
signal position_changed(player_index: int, new_position: PlayerData.PlayerPosition)
signal card_hand_changed(player_index: int)
signal win_condition_met(winner_index: int, reason: String)
signal damage_applied(attacker_index: int, target_index: int, amount: int)

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
	var actual: int = max(0, amount - p.damage_reduction)
	p.health = max(0, p.health - actual)
	player_damaged.emit(player_index, p.health)
	if actual > 0 and attacker_index >= 0 and attacker_index != player_index:
		players[attacker_index].damage_dealt_this_turn += actual
	damage_applied.emit(attacker_index, player_index, actual)
	if p.health == 0:
		_eliminate(player_index)
	check_win_conditions()

func apply_heal(player_index: int, amount: int) -> void:
	var p := players[player_index]
	if p.is_eliminated or p.position == PlayerData.PlayerPosition.AT_VAULT or amount <= 0:
		return
	p.health = min(p.max_health, p.health + amount + p.heal_bonus)
	player_healed.emit(player_index, p.health)

func add_gold(player_index: int, amount: int) -> void:
	var p := players[player_index]
	p.gold += amount
	gold_changed.emit(player_index, p.gold)
	check_win_conditions()

func add_gems(player_index: int, amount: int) -> void:
	var p := players[player_index]
	p.gems += amount + p.gem_gain_bonus
	gem_changed.emit(player_index, p.gems)

func spend_gems(player_index: int, amount: int) -> bool:
	var p := players[player_index]
	if p.gems < amount:
		return false
	p.gems -= amount
	gem_changed.emit(player_index, p.gems)
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
	players[player_index].cards_in_hand.append(card)
	card_hand_changed.emit(player_index)

func remove_card_from_hand(player_index: int, card: CardData) -> void:
	var hand := players[player_index].cards_in_hand
	if not hand.has(card):
		return
	hand.erase(card)
	card_hand_changed.emit(player_index)

func check_win_conditions() -> void:
	var alive := _alive_players()

	# Gold victory
	for i in players.size():
		if not players[i].is_eliminated and players[i].gold >= 20:
			win_condition_met.emit(i, "gold")
			return

	# Last standing
	if alive.size() == 1:
		win_condition_met.emit(alive[0], "elimination")
		return

	# Draw: all reach 0 HP in the same turn (all eliminated simultaneously)
	if alive.size() == 0:
		win_condition_met.emit(-1, "draw")

func _eliminate(player_index: int) -> void:
	players[player_index].is_eliminated = true
	player_eliminated.emit(player_index)

func _alive_players() -> Array[int]:
	var alive: Array[int] = []
	for i in players.size():
		if not players[i].is_eliminated:
			alive.append(i)
	return alive
