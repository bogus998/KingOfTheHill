class_name DragonDice
extends RefCounted
## Pure-logic dragon dice. No scene/game dependencies — just weighted rolls.
##
## Die 1 (action) decides what the dragon does; dice 2A/2B give the magnitude of
## fire damage / hoard gold-loss. The visual presentation lives in
## DragonDiceRoller; resolution of the outcomes lives in DragonManager.

enum Action { FIRE, HOARD, SLUMBER, ENVIRONMENT, WRATH }

## Action die — 6 weighted faces: 🔥 fire, 💰 hoard, 😴 slumber,
## 🌍 environment (×2), 🐉 wrath.
const ACTION_FACES: Array[Action] = [
	Action.FIRE,
	Action.HOARD,
	Action.SLUMBER,
	Action.ENVIRONMENT,
	Action.ENVIRONMENT,
	Action.WRATH,
]

## Magnitude die (shared by fire 2A and hoard 2B): faces 1,1,2,2,3,3.
const MAGNITUDE_FACES: Array[int] = [1, 1, 2, 2, 3, 3]

func roll_action() -> Action:
	return ACTION_FACES[randi() % ACTION_FACES.size()]

func roll_fire() -> int:
	return MAGNITUDE_FACES[randi() % MAGNITUDE_FACES.size()]

func roll_hoard() -> int:
	return MAGNITUDE_FACES[randi() % MAGNITUDE_FACES.size()]
