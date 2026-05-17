class_name ComboMasterEffect
extends CardEffect

@export var gold: int = 0

func _init(p_gold: int = 0) -> void:
	gold = p_gold

func on_roll_finalized(owner_index: int, final_faces: Array) -> void:
	if DiceResolver.has_combo_one_two_three(final_faces):
		PlayerManager.add_gold(owner_index, gold)
