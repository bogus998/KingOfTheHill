extends Node

var _effects: Dictionary = {}

func _ready() -> void:
	_effects = {
		"gain_gold_1":    func(idx: int): PlayerManager.add_gold(idx, 1),
		"heal_3":         func(idx: int): PlayerManager.apply_heal(idx, 3),
		"gain_gems_2":    func(idx: int): PlayerManager.add_gems(idx, 2),
		"damage_all_2":   func(idx: int): _damage_others(idx, 2),
		"gem_per_turn_1": func(idx: int): PlayerManager.add_gems(idx, 1),
	}
	CardShop.card_purchased.connect(_on_card_purchased)
	TurnManager.turn_started.connect(_on_turn_started)

func apply_immediate(card: CardData, player_index: int) -> void:
	if _effects.has(card.effect_id):
		_effects[card.effect_id].call(player_index)
	if card.card_type == CardData.CardType.ONE_TIME:
		PlayerManager.remove_card_from_hand(player_index, card)

func _on_card_purchased(player_index: int, card: CardData) -> void:
	if card.card_type == CardData.CardType.ONE_TIME:
		apply_immediate(card, player_index)

func _on_turn_started(player_index: int) -> void:
	if player_index >= PlayerManager.players.size():
		return
	for card in PlayerManager.players[player_index].cards_in_hand.duplicate():
		if card.card_type == CardData.CardType.PERMANENT and _effects.has(card.effect_id):
			_effects[card.effect_id].call(player_index)

func _damage_others(source_index: int, amount: int) -> void:
	for i in PlayerManager.players.size():
		if i != source_index and not PlayerManager.players[i].is_eliminated:
			PlayerManager.apply_damage(i, amount)
