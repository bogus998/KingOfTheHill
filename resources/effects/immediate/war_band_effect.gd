class_name WarBandEffect
extends CardEffect
## For each card in hand: gain +1 gems and take 1 damage.

func apply_immediate(owner_index: int) -> void:
	var card_count: int = PlayerManager.players[owner_index].cards_in_hand.size()
	for _i in card_count:
		PlayerManager.add_gems(owner_index, 1)
		PlayerManager.apply_damage(owner_index, 1)
