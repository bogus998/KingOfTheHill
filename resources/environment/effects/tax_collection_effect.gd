class_name TaxCollectionEffect
extends EnvironmentEffect
## At end of round all players pay 1 gold; players with 0 gold take 1 damage.

func on_round_ended() -> void:
	for i in PlayerManager.players.size():
		if PlayerManager.players[i].is_eliminated:
			continue
		if not PlayerManager.spend_gold(i, 1):
			PlayerManager.apply_damage(i, 1, -1)
