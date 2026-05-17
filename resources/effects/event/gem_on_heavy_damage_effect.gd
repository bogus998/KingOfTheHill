class_name GemOnHeavyDamageEffect
extends CardEffect
## The owner gains gems when hit for a heavy blow.

@export var threshold: int = 2
@export var gems: int = 1

func _init(p_threshold: int = 2, p_gems: int = 1) -> void:
	threshold = p_threshold
	gems = p_gems

func on_damage_applied(owner_index: int, _attacker_index: int, target_index: int, amount: int) -> void:
	if owner_index == target_index and amount >= threshold:
		PlayerManager.add_gems(target_index, gems)
