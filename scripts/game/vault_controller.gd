class_name VaultController
extends Panel

signal vault_entered(player_index: int)
signal vault_attacked(attacker_index: int, claw_count: int)
signal escape_requested(attacker_index: int, defender_index: int)
signal forced_escape(attacker_index: int, occupant_index: int)

var _turn_in_round: int = 0

func handle_claws(player_index: int, claw_count: int) -> void:
	var player := PlayerManager.players[player_index]

	var attack_damage := claw_count
	if _has_effect(player_index, CardEffectId.Id.CLAW_BONUS_DAMAGE_1):
		attack_damage += claw_count

	if player.position == PlayerData.PlayerPosition.OUTSIDE:
		var occupant := PlayerManager.get_vault_occupant()
		if occupant == -1:
			if claw_count < 1 + EnvironmentManager.vault_entry_surcharge():
				return  # Siege: not enough claws to breach the vault this round
			PlayerManager.set_position(player_index, PlayerData.PlayerPosition.AT_VAULT)
			PlayerManager.add_gems(player_index, 1)
			if _has_effect(player_index, CardEffectId.Id.GEM_PER_CLAW):
				PlayerManager.add_gems(player_index, claw_count)
			vault_entered.emit(player_index)
		else:
			PlayerManager.apply_damage(occupant, attack_damage, player_index)
			if _has_effect(player_index, CardEffectId.Id.GEM_PER_CLAW):
				PlayerManager.add_gems(player_index, claw_count)
			if PlayerManager.players[occupant].is_eliminated:
				PlayerManager.set_position(player_index, PlayerData.PlayerPosition.AT_VAULT)
				vault_entered.emit(player_index)
			elif _has_effect(player_index, CardEffectId.Id.INTIMIDATING_ROAR):
				forced_escape.emit(player_index, occupant)
			else:
				escape_requested.emit(player_index, occupant)
	else:
		var bonus_damage := 0
		if _has_effect(player_index, CardEffectId.Id.TUNNEL_FIGHTER) or _has_effect(player_index, CardEffectId.Id.VAULT_DWELLER):
			bonus_damage = 1
		for i in PlayerManager.players.size():
			var p := PlayerManager.players[i]
			if not p.is_eliminated and p.position == PlayerData.PlayerPosition.OUTSIDE:
				PlayerManager.apply_damage(i, attack_damage + bonus_damage, player_index)
		if _has_effect(player_index, CardEffectId.Id.GEM_PER_CLAW):
			PlayerManager.add_gems(player_index, claw_count)
		vault_attacked.emit(player_index, claw_count)

func handle_flee(attacker_index: int) -> void:
	var occupant := PlayerManager.get_vault_occupant()
	if occupant != -1:
		if not _has_effect(occupant, CardEffectId.Id.NO_FLEE_DAMAGE):
			PlayerManager.apply_damage(occupant, 1)
		if not PlayerManager.players[occupant].is_eliminated:
			if _has_effect(occupant, CardEffectId.Id.TUNNEL_FIGHTER):
				PlayerManager.apply_damage(attacker_index, 1)
		PlayerManager.set_position(occupant, PlayerData.PlayerPosition.OUTSIDE)
	PlayerManager.set_position(attacker_index, PlayerData.PlayerPosition.AT_VAULT)

func handle_stay() -> void:
	pass

func _ready() -> void:
	PlayerManager.position_changed.connect(_update_display)
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.round_started.connect(_on_round_started)
	_update_display(0, PlayerData.PlayerPosition.OUTSIDE)

func _on_round_started(_round_number: int) -> void:
	_turn_in_round = 0
	_update_round_label()

func _on_turn_started(_player_index: int) -> void:
	_turn_in_round += 1
	_update_round_label()

func _update_round_label() -> void:
	var label: Label = get_node_or_null("VBoxContainer/RoundLabel")
	if label == null:
		return
	label.text = "Round %d | Turn %d" % [TurnManager.round_number, _turn_in_round]

func _update_display(_idx: int, _pos: PlayerData.PlayerPosition) -> void:
	var label: Label = get_node_or_null("VBoxContainer/OccupantLabel")
	if label == null:
		return
	var occupant := PlayerManager.get_vault_occupant()
	label.text = "Empty" if occupant == -1 else PlayerManager.players[occupant].player_name

func _has_effect(player_index: int, effect_id: CardEffectId.Id) -> bool:
	for card in PlayerManager.players[player_index].cards_in_hand:
		if card.effect != null and card.effect.effect_id == effect_id:
			return true
	return false

