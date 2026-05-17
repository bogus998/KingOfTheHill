class_name GemForSelfDamageEffect
extends CardEffect

@export var gems: int = 0
@export var damage: int = 0

func _init(p_gems: int = 0, p_damage: int = 0) -> void:
	gems = p_gems
	damage = p_damage

func apply_immediate(owner_index: int) -> void:
	PlayerManager.add_gems(owner_index, gems)
	PlayerManager.apply_damage(owner_index, damage)
