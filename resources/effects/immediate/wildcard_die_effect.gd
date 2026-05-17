class_name WildcardDieEffect
extends CardEffect
## ONE_TIME deferred — flags the next roll to allow a wildcard die face.

func apply_immediate(owner_index: int) -> void:
	PlayerManager.players[owner_index].wildcard_pending = true
