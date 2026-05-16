class_name CardEffectHandler
extends RefCounted

func apply_immediate(card: CardData, player_index: int) -> void:
	_apply_effect(card.effect_id, player_index)
	if card.card_type == CardData.CardType.ONE_TIME:
		PlayerManager.remove_card_from_hand(player_index, card)

func _on_card_purchased(player_index: int, card: CardData) -> void:
	if card.card_type == CardData.CardType.ONE_TIME:
		apply_immediate(card, player_index)

func _on_turn_started(player_index: int) -> void:
	if player_index >= PlayerManager.players.size():
		return
	for card in PlayerManager.players[player_index].cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT:
			_apply_effect(card.effect_id, player_index)

func _apply_effect(effect_id: String, player_index: int) -> void:
	match effect_id:
		"gain_gold_1":    PlayerManager.add_gold(player_index, 1)
		"heal_3":         PlayerManager.apply_heal(player_index, 3)
		"gain_gems_2":    PlayerManager.add_gems(player_index, 2)
		"damage_all_2":   _damage_others(player_index, 2)
		"gem_per_turn_1": PlayerManager.add_gems(player_index, 1)

func _damage_others(source_index: int, amount: int) -> void:
	for i in PlayerManager.players.size():
		if i != source_index and not PlayerManager.players[i].is_eliminated:
			PlayerManager.apply_damage(i, amount)
