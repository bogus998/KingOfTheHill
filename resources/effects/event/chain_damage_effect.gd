class_name ChainDamageEffect
extends CardEffect
## When the owner deals damage, every other player also takes damage.

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func on_damage_applied(owner_index: int, attacker_index: int, target_index: int, _amount: int) -> void:
	if owner_index != attacker_index:
		return
	for i in PlayerManager.players.size():
		if i != attacker_index and i != target_index and not PlayerManager.players[i].is_eliminated:
			PlayerManager.apply_damage(i, amount)
