class_name GoldIfEmptyEffect
extends CardEffect

func on_turn_ended(owner_index: int) -> void:
	if PlayerManager.players[owner_index].gold == 0:
		PlayerManager.add_gold(owner_index, 1)
