extends Node

signal shop_updated(visible_cards: Array)
signal card_purchased(player_index: int, card: CardData)

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
	var card := visible_cards[slot_index]
	if not PlayerManager.spend_gems(player_index, card.gem_cost):
		return false
	visible_cards.remove_at(slot_index)
	if card.card_type == CardData.CardType.PERMANENT:
		PlayerManager.add_card_to_hand(player_index, card)
	else:
		# ONE_TIME cards go directly to an effect queue — handled by caller
		pass
	card_purchased.emit(player_index, card)
	_replenish()
	return true

func refresh_pool(player_index: int) -> bool:
	if not PlayerManager.spend_gems(player_index, REFRESH_COST):
		return false
	visible_cards.clear()
	_replenish()
	return true

func _replenish() -> void:
	while visible_cards.size() < VISIBLE_SLOTS and _deck.size() > 0:
		visible_cards.append(_deck.pop_back())
	shop_updated.emit(visible_cards)
