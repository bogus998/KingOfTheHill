class_name SetDieToOneEffect
extends CardEffect

func on_turn_started(owner_index: int) -> void:
	PlayerManager.players[owner_index].can_set_die_before_roll = true
