class_name PacifistCurseEffect
extends EnvironmentEffect
## No player can deal more than 2 damage in a single turn this round.

func damage_cap() -> int:
	return 2
