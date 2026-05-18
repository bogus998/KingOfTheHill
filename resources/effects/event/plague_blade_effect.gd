class_name PlagueBladeEffect
extends CardEffect

func on_damage_applied(owner_index: int, attacker_index: int, target_index: int, _amount: int) -> void:
	if owner_index == attacker_index and target_index != owner_index:
		PlayerManager.players[target_index].poison_stacks += 1
