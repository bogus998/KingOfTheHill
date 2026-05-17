class_name TripleOneExtraTurnEffect
extends CardEffect

func on_roll_finalized(owner_index: int, final_faces: Array) -> void:
	var p := PlayerManager.players[owner_index]
	if DiceResolver.count_face(final_faces, DiceResolver.DieFace.ONE) >= 3 \
			and not p.repeat_turn_used:
		p.repeat_turn_used = true
		TurnManager.request_repeat_turn(owner_index, 1)
