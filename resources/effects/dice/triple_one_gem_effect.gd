class_name TripleOneGemEffect
extends CardEffect

@export var gems: int = 0

func _init(p_gems: int = 0) -> void:
	gems = p_gems

func on_roll_finalized(owner_index: int, final_faces: Array) -> void:
	if DiceResolver.count_face(final_faces, DiceResolver.DieFace.ONE) >= 3:
		PlayerManager.add_gems(owner_index, gems)
