class_name UnderdogGemEffect
extends CardEffect
## +1 gems at turn end if the owner is tied for / has the least gems.

func on_turn_ended(owner_index: int) -> void:
	if PlayerManager.players[owner_index].is_eliminated:
		return
	var my_gems: int = PlayerManager.players[owner_index].gems
	for i in PlayerManager.players.size():
		if i != owner_index and not PlayerManager.players[i].is_eliminated:
			if PlayerManager.players[i].gems < my_gems:
				return
	PlayerManager.add_gems(owner_index, 1)
