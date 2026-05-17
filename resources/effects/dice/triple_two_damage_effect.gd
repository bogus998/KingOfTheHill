class_name TripleTwoDamageEffect
extends CardEffect

@export var damage: int = 0

func _init(p_damage: int = 0) -> void:
	damage = p_damage

func on_roll_finalized(owner_index: int, final_faces: Array) -> void:
	if DiceResolver.count_face(final_faces, DiceResolver.DieFace.TWO) >= 3:
		EffectUtils.damage_others(owner_index, damage)
