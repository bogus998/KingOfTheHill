class_name WarDrumsEffect
extends CardEffect
## Rolling 4+ dice-gold arms War Drums; at turn end every other living player
## takes a -1 die penalty next turn.

func on_roll_finalized(owner_index: int, final_faces: Array) -> void:
	if DiceResolver.resolve(final_faces)["gold"] >= 4:
		PlayerManager.players[owner_index].war_drums_triggered = true

func on_turn_ended(owner_index: int) -> void:
	var p := PlayerManager.players[owner_index]
	if not p.war_drums_triggered:
		return
	p.war_drums_triggered = false
	for i in PlayerManager.players.size():
		if i != owner_index and not PlayerManager.players[i].is_eliminated:
			PlayerManager.players[i].pending_die_penalty += 1
