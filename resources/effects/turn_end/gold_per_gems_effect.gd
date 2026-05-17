class_name GoldPerGemsEffect
extends CardEffect
## +1 gold per `per` gems held, at turn end.

@export var per: int = 6

func _init(p_per: int = 6) -> void:
	per = p_per

func on_turn_ended(owner_index: int) -> void:
	var bonus: int = PlayerManager.players[owner_index].gems / per
	if bonus > 0:
		PlayerManager.add_gold(owner_index, bonus)
