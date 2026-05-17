class_name GemIfEmptyEffect
extends CardEffect

func on_turn_ended(owner_index: int) -> void:
	if PlayerManager.players[owner_index].gems == 0:
		PlayerManager.add_gems(owner_index, 1)
