class_name EffectUtils
## Shared multi-target helpers used by CardEffect subclasses.

static func damage_others(source_index: int, amount: int) -> void:
	for i in PlayerManager.players.size():
		if i != source_index and not PlayerManager.players[i].is_eliminated:
			PlayerManager.apply_damage(i, amount, source_index)

static func damage_all(source_index: int, amount: int) -> void:
	for i in PlayerManager.players.size():
		if not PlayerManager.players[i].is_eliminated:
			PlayerManager.apply_damage(i, amount, source_index)

static func steal_gold_from_others(source_index: int, amount: int) -> void:
	for i in PlayerManager.players.size():
		if i != source_index and not PlayerManager.players[i].is_eliminated:
			var p := PlayerManager.players[i]
			var stolen: int = min(p.gold, amount)
			if stolen > 0:
				p.gold -= stolen
				PlayerManager.gold_changed.emit(i, p.gold)
				PlayerManager.add_gold(source_index, stolen)

static func steal_half_gems_from_others(source_index: int) -> void:
	for i in PlayerManager.players.size():
		if i != source_index and not PlayerManager.players[i].is_eliminated:
			var lose: int = PlayerManager.players[i].gems / 2
			if lose > 0:
				PlayerManager.spend_gems(i, lose)
				PlayerManager.add_gems(source_index, lose)
