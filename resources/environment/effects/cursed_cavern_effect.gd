class_name CursedCavernEffect
extends EnvironmentEffect
## Any player who rolls all 3 times loses 1 HP.

func on_roll_finalized(player_index: int, roll_count: int, _final_faces: Array) -> void:
	if roll_count >= 3:
		PlayerManager.apply_damage(player_index, 1, -1)
