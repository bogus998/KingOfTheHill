class_name GoldFeverEffect
extends EnvironmentEffect
## Whenever a player gains gold, they take damage equal to the amount gained.

func on_gold_gained(player_index: int, amount: int) -> void:
	if amount > 0:
		PlayerManager.apply_damage(player_index, amount, -1)
