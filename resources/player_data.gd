class_name PlayerData
extends Resource

enum PlayerPosition { OUTSIDE, AT_VAULT }

@export var player_name: String = "Player"
@export var health: int = 10
@export var gold: int = 0
@export var gems: int = 0
@export var position: PlayerPosition = PlayerPosition.OUTSIDE
@export var is_eliminated: bool = false
@export var cards_in_hand: Array[CardData] = []
@export var is_bot: bool = false
