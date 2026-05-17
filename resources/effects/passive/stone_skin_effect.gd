class_name StoneSkinEffect
extends CardEffect

func on_turn_started(owner_index: int) -> void:
	PlayerManager.players[owner_index].camouflage_active = true
