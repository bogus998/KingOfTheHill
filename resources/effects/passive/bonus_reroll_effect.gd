class_name BonusRerollEffect
extends CardEffect

func on_turn_started(owner_index: int) -> void:
	PlayerManager.players[owner_index].has_free_reroll_after_max = true
