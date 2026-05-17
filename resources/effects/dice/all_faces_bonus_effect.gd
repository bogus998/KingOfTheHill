class_name AllFacesBonusEffect
extends CardEffect

@export var gems: int = 0

func _init(p_gems: int = 0) -> void:
	gems = p_gems

func on_roll_finalized(owner_index: int, final_faces: Array) -> void:
	if DiceResolver.has_all_six_faces(final_faces):
		PlayerManager.add_gems(owner_index, gems)
