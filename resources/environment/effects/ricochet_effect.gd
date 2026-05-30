class_name RicochetEffect
extends EnvironmentEffect
## Any damage dealt also hits the attacker for 1.
## The reflected hit uses attacker -1 so it never ricochets again.

func on_damage_applied(attacker_index: int, target_index: int, amount: int) -> void:
	if amount > 0 and attacker_index >= 0 and attacker_index != target_index:
		PlayerManager.apply_damage(attacker_index, 1, -1)
