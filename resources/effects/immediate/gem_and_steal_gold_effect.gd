class_name GemAndStealGoldEffect
extends CardEffect

@export var gems: int = 0

func _init(p_gems: int = 0) -> void:
	gems = p_gems

func apply_immediate(owner_index: int) -> void:
	PlayerManager.add_gems(owner_index, gems)
	EffectUtils.steal_half_gold_from_others(owner_index)
