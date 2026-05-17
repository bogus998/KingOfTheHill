class_name DodgeRollEffect
extends CardEffect

func apply_immediate(owner_index: int) -> void:
	var p := PlayerManager.players[owner_index]
	if not p.gold_dodge_active:
		if PlayerManager.spend_gold(owner_index, 2):
			p.gold_dodge_active = true
