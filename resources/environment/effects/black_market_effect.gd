class_name BlackMarketEffect
extends EnvironmentEffect
## All shop cards cost -1 this round.

func shop_cost_delta() -> int:
	return -1
