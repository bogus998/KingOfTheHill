class_name PlagueBladeEffect
extends CardEffect

func apply_immediate(owner_index: int) -> void:
	for i in PlayerManager.players.size():
		if i != owner_index and not PlayerManager.players[i].is_eliminated:
			PlayerManager.players[i].poison_stacks += 1
