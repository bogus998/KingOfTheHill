class_name DamageAllEffect
extends CardEffect

@export var amount: int = 0
@export var include_self: bool = false

func _init(p_amount: int = 0, p_include_self: bool = false) -> void:
	amount = p_amount
	include_self = p_include_self

func apply_immediate(owner_index: int) -> void:
	if include_self:
		EffectUtils.damage_all(owner_index, amount)
	else:
		EffectUtils.damage_others(owner_index, amount)
