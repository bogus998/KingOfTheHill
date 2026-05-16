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
@export var spent_one_time_cards: Array[CardData] = []
@export var is_bot: bool = false

# Stat modifiers set on card purchase (persist while card is in hand)
@export var damage_reduction: int = 0
@export var max_health: int = 10
@export var gem_gain_bonus: int = 0
@export var heal_bonus: int = 0

# Per-turn tracking (reset at turn start)
var damage_dealt_this_turn: int = 0
