class_name CardEffect
extends Resource
## Base class for all card effects.
##
## A CardEffect carries the behaviour of a card. Each CardData references one via
## its `effect` property. CardEffectHandler fires the lifecycle hooks below at the
## appropriate moments; concrete subclasses override only the hooks they need.
##
## The base class itself is a valid no-op effect — it is used directly as the stub
## for card effects that are not yet implemented.

@export var effect_id: CardEffectId.Id = CardEffectId.Id.NONE

## ONE_TIME card played / immediate effect.
func apply_immediate(_owner_index: int) -> void:
	pass

## This permanent card was just bought — one-shot setup (stat modifiers, charges).
func on_acquired(_owner_index: int) -> void:
	pass

## Any card was bought while this permanent is in hand.
func on_any_card_purchased(_owner_index: int, _bought_card: CardData) -> void:
	pass

func on_turn_started(_owner_index: int) -> void:
	pass

func on_turn_ended(_owner_index: int) -> void:
	pass

func on_roll_finalized(_owner_index: int, _final_faces: Array) -> void:
	pass

func on_damage_applied(_owner_index: int, _attacker_index: int, _target_index: int, _amount: int) -> void:
	pass

func on_player_eliminated(_owner_index: int, _eliminated_index: int) -> void:
	pass

func on_position_changed(_owner_index: int, _new_pos: PlayerData.PlayerPosition) -> void:
	pass

## Turn-start income/damage passives are skipped on repeated turns.
func is_income_passive() -> bool:
	return false
