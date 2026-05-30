class_name CaveCollapseEffect
extends EnvironmentEffect
## All players roll with 2 fewer dice this round.

func dice_count_delta() -> int:
	return -2
