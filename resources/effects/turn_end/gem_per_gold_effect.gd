class_name GemPerGoldEffect
extends CardEffect
## +1 gems per `per` gold held, at turn end.

@export var per: int = 6

func _init(p_per: int = 6) -> void:
	per = p_per

func on_turn_ended(owner_index: int) -> void:
	var bonus: int = PlayerManager.players[owner_index].gold / per
	if bonus > 0:
		PlayerManager.add_gems(owner_index, bonus)
