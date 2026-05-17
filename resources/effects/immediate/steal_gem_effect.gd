class_name StealGemEffect
extends CardEffect

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func apply_immediate(owner_index: int) -> void:
	EffectUtils.steal_gems_from_others(owner_index, amount)
