class_name GoldenRollEffect
extends EnvironmentEffect
## Any player who stops at roll 1 gains 2 gems.

func on_roll_finalized(player_index: int, roll_count: int, _final_faces: Array) -> void:
	if roll_count == 1:
		PlayerManager.add_gems(player_index, 2)
