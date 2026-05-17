class_name GemPerTurnEffect
extends CardEffect

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func on_turn_started(owner_index: int) -> void:
	PlayerManager.add_gems(owner_index, amount)

func is_income_passive() -> bool:
	return true
