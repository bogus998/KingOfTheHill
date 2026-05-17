class_name GoldAndStealGemsEffect
extends CardEffect

@export var gold: int = 0

func _init(p_gold: int = 0) -> void:
	gold = p_gold

func apply_immediate(owner_index: int) -> void:
	PlayerManager.add_gold(owner_index, gold)
	EffectUtils.steal_half_gems_from_others(owner_index)
