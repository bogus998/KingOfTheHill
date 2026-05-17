class_name HealEffect
extends CardEffect

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func apply_immediate(owner_index: int) -> void:
	PlayerManager.apply_heal(owner_index, amount)
