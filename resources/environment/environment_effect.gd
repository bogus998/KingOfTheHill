class_name EnvironmentEffect
extends Resource
## Base class for an Environment Card's behaviour. One is active for exactly the
## round after the dragon draws it, then dismissed (see [[environment_manager]]).
##
## Mirrors the CardEffect pattern but with two override surfaces:
##   • Reactive hooks — EnvironmentManager forwards game events to the active card.
##   • Query getters  — managers consult the active card at decision points
##     (the consultation sites are wired in M-Dragon-6). Defaults are neutral so
##     the base class is a valid no-op card.

@export var card_name: String = ""
@export var description: String = ""

# ── Reactive hooks (forwarded by EnvironmentManager while this card is active) ──

func on_round_started() -> void:
	pass

func on_round_ended() -> void:
	pass

func on_damage_applied(_attacker_index: int, _target_index: int, _amount: int) -> void:
	pass

func on_gold_gained(_player_index: int, _amount: int) -> void:
	pass

func on_roll_finalized(_player_index: int, _roll_count: int, _final_faces: Array) -> void:
	pass

# ── Query getters (consulted by managers; neutral defaults) ───────────────────

## Max rolls allowed this round, or -1 for no override.
func roll_limit() -> int:
	return -1

## Change to each player's dice count this round.
func dice_count_delta() -> int:
	return 0

## Change to shop card gold cost this round.
func shop_cost_delta() -> int:
	return 0

## Extra claws an outside player needs to enter the vault this round.
func vault_entry_surcharge() -> int:
	return 0

## Whether players may buy shop cards this round.
func purchasing_allowed() -> bool:
	return true

## Whether players' own cards function this round.
func cards_active() -> bool:
	return true

## Max damage a player may deal in one turn this round, or -1 for no cap.
func damage_cap() -> int:
	return -1

## Whether every player gets one free reroll per turn this round.
func grants_free_reroll() -> bool:
	return false

## Extra gold the vault holder earns when gaining gold this round.
func vault_holder_gold_bonus() -> int:
	return 0

## Whether the vault holder is barred from accumulating gold this round.
func blocks_vault_holder_gold() -> bool:
	return false
