class_name ReflectiveEffect
extends CardEffect
## When the owner is hit, reflect damage back to the attacker.

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func on_damage_applied(owner_index: int, attacker_index: int, target_index: int, _amount: int) -> void:
	if owner_index == target_index:
		PlayerManager.apply_damage(attacker_index, amount)
		triggered.emit("on_damage_applied")
