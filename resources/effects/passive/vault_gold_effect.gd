class_name VaultGoldEffect
extends CardEffect
## Grants gold each turn start while the owner is at the vault.

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func on_turn_started(owner_index: int) -> void:
	if PlayerManager.players[owner_index].position == PlayerData.PlayerPosition.AT_VAULT:
		PlayerManager.add_gold(owner_index, amount)

func is_income_passive() -> bool:
	return true
