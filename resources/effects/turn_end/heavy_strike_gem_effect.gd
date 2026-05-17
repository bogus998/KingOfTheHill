class_name HeavyStrikeGemEffect
extends CardEffect

func on_turn_ended(owner_index: int) -> void:
	if PlayerManager.players[owner_index].damage_dealt_this_turn >= 3:
		PlayerManager.add_gems(owner_index, 2)
