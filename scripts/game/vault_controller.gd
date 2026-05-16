class_name VaultController
extends Panel

signal vault_entered(player_index: int)
signal vault_attacked(attacker_index: int, claw_count: int)
signal escape_requested(attacker_index: int, defender_index: int)

func handle_claws(player_index: int, claw_count: int) -> void:
	var player := PlayerManager.players[player_index]
	if player.position == PlayerData.PlayerPosition.OUTSIDE:
		var occupant := PlayerManager.get_vault_occupant()
		if occupant == -1:
			PlayerManager.set_position(player_index, PlayerData.PlayerPosition.AT_VAULT)
			PlayerManager.add_gold(player_index, 1)
			vault_entered.emit(player_index)
		else:
			PlayerManager.apply_damage(occupant, claw_count)
			if PlayerManager.players[occupant].is_eliminated:
				PlayerManager.set_position(player_index, PlayerData.PlayerPosition.AT_VAULT)
				vault_entered.emit(player_index)
			else:
				escape_requested.emit(player_index, occupant)
	else:
		for i in PlayerManager.players.size():
			var p := PlayerManager.players[i]
			if not p.is_eliminated and p.position == PlayerData.PlayerPosition.OUTSIDE:
				PlayerManager.apply_damage(i, claw_count)
		vault_attacked.emit(player_index, claw_count)

func handle_flee(attacker_index: int) -> void:
	var occupant := PlayerManager.get_vault_occupant()
	if occupant != -1:
		PlayerManager.set_position(occupant, PlayerData.PlayerPosition.OUTSIDE)
	PlayerManager.set_position(attacker_index, PlayerData.PlayerPosition.AT_VAULT)

func handle_stay() -> void:
	pass

func _ready() -> void:
	PlayerManager.position_changed.connect(_update_display)
	_update_display(0, PlayerData.PlayerPosition.OUTSIDE)

func _update_display(_idx: int, _pos: PlayerData.PlayerPosition) -> void:
	var label: Label = get_node_or_null("VBoxContainer/OccupantLabel")
	if label == null:
		return
	var occupant := PlayerManager.get_vault_occupant()
	label.text = "Empty" if occupant == -1 else PlayerManager.players[occupant].player_name
