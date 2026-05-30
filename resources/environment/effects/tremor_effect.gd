class_name TremorEffect
extends EnvironmentEffect
## All players discard 1 card from their hand when the round begins.

func on_round_started() -> void:
	for i in PlayerManager.players.size():
		var hand: Array = PlayerManager.players[i].cards_in_hand
		if not hand.is_empty():
			PlayerManager.remove_card_from_hand(i, hand[0])
