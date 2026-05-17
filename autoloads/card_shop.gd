extends Node

signal shop_updated(visible_cards: Array)
signal card_purchased(player_index: int, card: CardData)
signal new_card_revealed(card: CardData, slot_index: int)

const VISIBLE_SLOTS := 3
const REFRESH_COST := 2

var _deck: Array[CardData] = []
var visible_cards: Array[CardData] = []

func _ready() -> void:
	reset()

func reset() -> void:
	_deck = CardCatalog.load_all_cards()
	_deck.shuffle()
	visible_cards.clear()
	_replenish()

func purchase(slot_index: int, player_index: int) -> bool:
	if slot_index >= visible_cards.size():
		return false
	var card: CardData = visible_cards[slot_index]
	var effective_cost: int = max(0, card.gold_cost - discount_for(player_index))
	if not PlayerManager.spend_gold(player_index, effective_cost):
		return false
	visible_cards.remove_at(slot_index)
	if card.card_type == CardData.CardType.PERMANENT:
		PlayerManager.add_card_to_hand(player_index, card)
	else:
		pass  # effect applied by CardEffectHandler via card_purchased signal
	card_purchased.emit(player_index, card)
	_replenish()
	return true

func refresh_pool(player_index: int) -> bool:
	if not PlayerManager.spend_gold(player_index, REFRESH_COST):
		return false
	visible_cards.clear()
	_replenish()
	return true

func discount_for(player_index: int) -> int:
	var count := 0
	for c in PlayerManager.players[player_index].cards_in_hand:
		if c.effect != null and c.effect.effect_id == CardEffectId.Id.GOLD_DISCOUNT_1:
			count += 1
	return count

func peek_top() -> CardData:
	return _deck.back() if not _deck.is_empty() else null

func purchase_top(player_index: int) -> bool:
	if _deck.is_empty():
		return false
	var card: CardData = _deck.pop_back()
	var effective_cost: int = max(0, card.gold_cost - discount_for(player_index))
	if not PlayerManager.spend_gold(player_index, effective_cost):
		_deck.push_back(card)
		return false
	if card.card_type == CardData.CardType.PERMANENT:
		PlayerManager.add_card_to_hand(player_index, card)
	card_purchased.emit(player_index, card)
	_replenish()
	return true

func purchase_specific_card(card: CardData, player_index: int) -> bool:
	var slot_index := visible_cards.find(card)
	if slot_index < 0:
		return false
	return purchase(slot_index, player_index)

func _replenish() -> void:
	while visible_cards.size() < VISIBLE_SLOTS and _deck.size() > 0:
		visible_cards.append(_deck.pop_back())
		new_card_revealed.emit(visible_cards.back(), visible_cards.size() - 1)
	shop_updated.emit(visible_cards)
