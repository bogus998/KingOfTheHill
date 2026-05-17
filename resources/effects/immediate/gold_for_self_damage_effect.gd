class_name GoldForSelfDamageEffect
extends CardEffect

@export var gold: int = 0
@export var damage: int = 0

func _init(p_gold: int = 0, p_damage: int = 0) -> void:
	gold = p_gold
	damage = p_damage

func apply_immediate(owner_index: int) -> void:
	PlayerManager.add_gold(owner_index, gold)
	PlayerManager.apply_damage(owner_index, damage)
