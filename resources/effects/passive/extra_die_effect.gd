class_name ExtraDieEffect
extends CardEffect

func on_turn_started(owner_index: int) -> void:
	PlayerManager.players[owner_index].die_count_modifier += 1
