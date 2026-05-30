class_name SilenceEffect
extends EnvironmentEffect
## All player cards are inactive this round.

func cards_active() -> bool:
	return false
