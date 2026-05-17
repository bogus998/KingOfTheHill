class_name TripleOneGoldEffect
extends CardEffect

@export var gold: int = 0

func _init(p_gold: int = 0) -> void:
	gold = p_gold

func on_roll_finalized(owner_index: int, final_faces: Array) -> void:
	if DiceResolver.count_face(final_faces, DiceResolver.DieFace.ONE) >= 3:
		PlayerManager.add_gold(owner_index, gold)
