class_name LonelyCrownEffect
extends EnvironmentEffect
## Vault holder takes 1 damage at end of round.

func on_round_ended() -> void:
	var occupant := PlayerManager.get_vault_occupant()
	if occupant != -1:
		PlayerManager.apply_damage(occupant, 1, -1)
