class_name GoldOnKillEffect
extends CardEffect
## The owner gains gold whenever another player is eliminated.

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func on_player_eliminated(owner_index: int, eliminated_index: int) -> void:
	if owner_index != eliminated_index and not PlayerManager.players[owner_index].is_eliminated:
		PlayerManager.add_gold(owner_index, amount)
