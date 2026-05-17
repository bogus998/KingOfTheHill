class_name AllFacesBonusEffect
extends CardEffect

@export var gold: int = 0

func _init(p_gold: int = 0) -> void:
	gold = p_gold

func on_roll_finalized(owner_index: int, final_faces: Array) -> void:
	if DiceResolver.has_all_six_faces(final_faces):
		PlayerManager.add_gold(owner_index, gold)
