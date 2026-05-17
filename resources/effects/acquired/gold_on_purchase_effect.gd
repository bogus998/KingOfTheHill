class_name GoldOnPurchaseEffect
extends CardEffect
## Grants gold whenever any card is bought while this permanent is in hand.

@export var amount: int = 0

func _init(p_amount: int = 0) -> void:
	amount = p_amount

func on_any_card_purchased(owner_index: int, _bought_card: CardData) -> void:
	PlayerManager.add_gold(owner_index, amount)
