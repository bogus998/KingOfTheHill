class_name CardData
extends Resource

enum CardType { ONE_TIME, PERMANENT, ACTIONABLE }

@export var card_name: String = ""
@export var description: String = ""
@export var gold_cost: int = 1
@export var card_type: CardType = CardType.ONE_TIME
@export var card_icon: Texture2D
@export var effect: CardEffect
@export var charges: int = 0
