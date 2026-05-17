class_name ResolutionController
extends RefCounted

func apply_non_claw(player_index: int, result: Dictionary) -> void:
	if result["gems"] > 0:
		PlayerManager.add_gems(player_index, result["gems"])
	if result["gold"] > 0:
		PlayerManager.add_gold(player_index, result["gold"])
	if result["hearts"] > 0:
		if PlayerManager.players[player_index].position != PlayerData.PlayerPosition.AT_VAULT:
			PlayerManager.apply_heal(player_index, result["hearts"])
