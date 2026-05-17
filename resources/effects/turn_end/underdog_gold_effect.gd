class_name UnderdogGoldEffect
extends CardEffect
## +1 gold at turn end if the owner is tied for / has the least gold.

func on_turn_ended(owner_index: int) -> void:
	if PlayerManager.players[owner_index].is_eliminated:
		return
	var my_gold: int = PlayerManager.players[owner_index].gold
	for i in PlayerManager.players.size():
		if i != owner_index and not PlayerManager.players[i].is_eliminated:
			if PlayerManager.players[i].gold < my_gold:
				return
	PlayerManager.add_gold(owner_index, 1)
