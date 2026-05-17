class_name GemAndHealEffect
extends CardEffect

@export var gems: int = 0
@export var heal: int = 0

func _init(p_gems: int = 0, p_heal: int = 0) -> void:
	gems = p_gems
	heal = p_heal

func apply_immediate(owner_index: int) -> void:
	PlayerManager.add_gems(owner_index, gems)
	PlayerManager.apply_heal(owner_index, heal)
