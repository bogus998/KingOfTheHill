class_name HeavyStrikeGoldEffect
extends CardEffect

func on_turn_ended(owner_index: int) -> void:
	if PlayerManager.players[owner_index].damage_dealt_this_turn >= 3:
		PlayerManager.add_gold(owner_index, 2)
