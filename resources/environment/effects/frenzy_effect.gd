class_name FrenzyEffect
extends EnvironmentEffect
## Player who deals the most damage this round gains 3 gold (ties all rewarded).

var _damage: Dictionary = {}   # player_index -> damage dealt this round

func on_round_started() -> void:
	_damage.clear()

func on_damage_applied(attacker_index: int, _target_index: int, amount: int) -> void:
	if attacker_index >= 0 and amount > 0:
		_damage[attacker_index] = _damage.get(attacker_index, 0) + amount

func on_round_ended() -> void:
	var best := 0
	for v in _damage.values():
		best = maxi(best, v)
	if best <= 0:
		return
	for idx in _damage:
		if _damage[idx] == best:
			PlayerManager.add_gold(idx, 3)
