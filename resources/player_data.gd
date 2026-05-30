class_name PlayerData
extends Resource

enum PlayerPosition { OUTSIDE, AT_VAULT }

@export var player_name: String = "Player"
@export var health: int = 10
@export var gems: int = 0
@export var gold: int = 0
@export var position: PlayerPosition = PlayerPosition.OUTSIDE
@export var is_eliminated: bool = false
@export var cards_in_hand: Array[CardData] = []
@export var spent_one_time_cards: Array[CardData] = []
@export var is_bot: bool = false

# Stat modifiers set on card purchase (persist while card is in hand)
@export var damage_reduction: int = 0
@export var max_health: int = 10
@export var gold_gain_bonus: int = 0
@export var heal_bonus: int = 0

# Per-turn tracking (reset at turn start)
var damage_dealt_this_turn: int = 0
var die_count_modifier: int = 0
var extra_rerolls_available: int = 0
var has_free_reroll_after_max: bool = false
var free_reroll_threes: bool = false
var pending_die_penalty: int = 0
var repeat_turn_used: bool = false
var war_drums_triggered: bool = false
var poison_stacks: int = 0
var shrink_stacks: int = 0
var camouflage_active: bool = false
var gold_dodge_active: bool = false
var nimble_dodge_used_this_turn: bool = false
var nimble_dodge_active: bool = false
var die_picker_used_this_turn: bool = false
var die_jacker_used_this_turn: bool = false
var die_jacker_pending: bool = false
