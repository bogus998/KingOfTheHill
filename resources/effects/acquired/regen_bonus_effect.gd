class_name RegenBonusEffect
extends CardEffect

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func on_acquired(owner_index: int) -> void:
	PlayerManager.players[owner_index].heal_bonus += amount
