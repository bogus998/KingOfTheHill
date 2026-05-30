class_name GemSurgeEffect
extends EnvironmentEffect
## Every 2 Hearts rolled generates 1 gem.

func on_roll_finalized(player_index: int, _roll_count: int, final_faces: Array) -> void:
	var hearts := 0
	for f in final_faces:
		if f == DiceResolver.DieFace.HEART:
			hearts += 1
	var gems := hearts / 2
	if gems > 0:
		PlayerManager.add_gems(player_index, gems)
