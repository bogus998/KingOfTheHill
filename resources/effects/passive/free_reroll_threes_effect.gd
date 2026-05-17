class_name FreeRerollThreesEffect
extends CardEffect

func on_turn_started(owner_index: int) -> void:
	PlayerManager.players[owner_index].free_reroll_threes = true
