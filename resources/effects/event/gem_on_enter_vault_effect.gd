class_name GemOnEnterVaultEffect
extends CardEffect

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func on_position_changed(owner_index: int, new_pos: PlayerData.PlayerPosition) -> void:
	if new_pos == PlayerData.PlayerPosition.AT_VAULT:
		PlayerManager.add_gems(owner_index, amount)
