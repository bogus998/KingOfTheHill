class_name GoldAndHealEffect
extends CardEffect

@export var gold: int = 0
@export var heal: int = 0

func _init(p_gold: int = 0, p_heal: int = 0) -> void:
	gold = p_gold
	heal = p_heal

func apply_immediate(owner_index: int) -> void:
	PlayerManager.add_gold(owner_index, gold)
	PlayerManager.apply_heal(owner_index, heal)
