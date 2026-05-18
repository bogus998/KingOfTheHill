class_name LifeDrainEffect
extends CardEffect
## Heal the owner whenever they deal damage.

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func on_damage_applied(owner_index: int, attacker_index: int, _target_index: int, _amount: int) -> void:
	if owner_index == attacker_index:
		PlayerManager.apply_heal(attacker_index, amount)
		triggered.emit("on_damage_applied")
