class_name GameStateSerializer
## Host→client state sync (Phase 3). The ONLY unit aware of how the authoritative
## game state maps to a transferable Dictionary — the gameplay managers and data
## resources stay network-agnostic and are touched only through their public API.
##
## `snapshot()` reads the host's state; `apply()` writes it back on a client. apply
## is deliberately SILENT (it emits no simulation signals — replaying turn/round/
## damage signals on a client would re-run the host-only simulation and corrupt
## state). The client redraws afterwards via NetworkManager.snapshot_applied.
##
## Cards are referenced by their stable `card_name` (not resource_path: in-hand
## cards are runtime duplicates whose resource_path is empty). Names are resolved
## back through [[card_catalog]] / [[environment_deck]].

static var _card_index: Dictionary = {}   # card_name -> CardData (catalog source)
static var _env_index: Dictionary = {}    # card_name -> EnvironmentEffect (deck source)

# ── Snapshot (host) ───────────────────────────────────────────────────────────

static func snapshot() -> Dictionary:
	return {
		"players": _snapshot_players(),
		"turn": _snapshot_turn(),
		"shop": _snapshot_shop(),
		"dragon": _snapshot_dragon(),
		"environment": _snapshot_environment(),
	}

static func _snapshot_players() -> Array:
	var out: Array = []
	for p in PlayerManager.players:
		out.append(_player_to_dict(p))
	return out

static func _snapshot_turn() -> Dictionary:
	return {
		"phase": int(TurnManager.current_phase),
		"current_player": TurnManager.current_player_index,
		"round": TurnManager.round_number,
		"roll_count": TurnManager.roll_count,
		"is_active": TurnManager.is_game_active,
	}

static func _snapshot_shop() -> Array:
	var names: Array = []
	for c in CardShop.visible_cards:
		names.append(c.card_name)
	return names

static func _snapshot_dragon() -> Dictionary:
	return {
		"rage": DragonManager.rage,
		"threshold": DragonManager.rage_threshold,
		"awakenings": DragonManager.awakening_count,
		"pending": DragonManager.is_awakening_pending,
	}

static func _snapshot_environment() -> Dictionary:
	return {
		"active": EnvironmentManager.active_card.card_name if EnvironmentManager.active_card != null else "",
		"pending": EnvironmentManager.pending_card.card_name if EnvironmentManager.pending_card != null else "",
	}

# ── Apply (client) ────────────────────────────────────────────────────────────

static func apply(state: Dictionary) -> void:
	_apply_players(state.get("players", []))
	_apply_turn(state.get("turn", {}))
	_apply_shop(state.get("shop", []))
	_apply_dragon(state.get("dragon", {}))
	_apply_environment(state.get("environment", {}))

static func _apply_players(arr: Array) -> void:
	var rebuilt: Array[PlayerData] = []
	for d in arr:
		rebuilt.append(_player_from_dict(d))
	PlayerManager.players = rebuilt

static func _apply_turn(d: Dictionary) -> void:
	TurnManager.current_phase = d.get("phase", 0)
	TurnManager.current_player_index = d.get("current_player", 0)
	TurnManager.round_number = d.get("round", 1)
	TurnManager.roll_count = d.get("roll_count", 0)
	TurnManager.is_game_active = d.get("is_active", true)

static func _apply_shop(names: Array) -> void:
	var index := _cards_by_name()
	var cards: Array[CardData] = []
	for n in names:
		var src: CardData = index.get(n)
		if src != null:
			cards.append(src)
	CardShop.visible_cards = cards

static func _apply_dragon(d: Dictionary) -> void:
	DragonManager.restore_state(
		d.get("rage", 0), d.get("threshold", 0),
		d.get("awakenings", 0), d.get("pending", false))

static func _apply_environment(d: Dictionary) -> void:
	EnvironmentManager.active_card = _env_by_name(d.get("active", ""))
	EnvironmentManager.pending_card = _env_by_name(d.get("pending", ""))

# ── PlayerData <-> Dictionary ─────────────────────────────────────────────────

static func _player_to_dict(p: PlayerData) -> Dictionary:
	return {
		"player_name": p.player_name,
		"health": p.health,
		"gems": p.gems,
		"gold": p.gold,
		"position": int(p.position),
		"is_eliminated": p.is_eliminated,
		"is_bot": p.is_bot,
		"cards_in_hand": _cards_to_array(p.cards_in_hand),
		"spent_one_time_cards": _cards_to_array(p.spent_one_time_cards),
		"damage_reduction": p.damage_reduction,
		"max_health": p.max_health,
		"gold_gain_bonus": p.gold_gain_bonus,
		"heal_bonus": p.heal_bonus,
		"damage_dealt_this_turn": p.damage_dealt_this_turn,
		"die_count_modifier": p.die_count_modifier,
		"extra_rerolls_available": p.extra_rerolls_available,
		"has_free_reroll_after_max": p.has_free_reroll_after_max,
		"free_reroll_threes": p.free_reroll_threes,
		"pending_die_penalty": p.pending_die_penalty,
		"repeat_turn_used": p.repeat_turn_used,
		"war_drums_triggered": p.war_drums_triggered,
		"poison_stacks": p.poison_stacks,
		"shrink_stacks": p.shrink_stacks,
		"camouflage_active": p.camouflage_active,
		"nimble_dodge_used_this_turn": p.nimble_dodge_used_this_turn,
		"nimble_dodge_active": p.nimble_dodge_active,
		"die_picker_used_this_turn": p.die_picker_used_this_turn,
		"die_jacker_used_this_turn": p.die_jacker_used_this_turn,
		"die_jacker_pending": p.die_jacker_pending,
	}

static func _player_from_dict(d: Dictionary) -> PlayerData:
	var p := PlayerData.new()
	p.player_name = d.get("player_name", "Player")
	p.health = d.get("health", 10)
	p.gems = d.get("gems", 0)
	p.gold = d.get("gold", 0)
	p.position = d.get("position", PlayerData.PlayerPosition.OUTSIDE)
	p.is_eliminated = d.get("is_eliminated", false)
	p.is_bot = d.get("is_bot", false)
	p.cards_in_hand = _cards_from_array(d.get("cards_in_hand", []))
	p.spent_one_time_cards = _cards_from_array(d.get("spent_one_time_cards", []))
	p.damage_reduction = d.get("damage_reduction", 0)
	p.max_health = d.get("max_health", 10)
	p.gold_gain_bonus = d.get("gold_gain_bonus", 0)
	p.heal_bonus = d.get("heal_bonus", 0)
	p.damage_dealt_this_turn = d.get("damage_dealt_this_turn", 0)
	p.die_count_modifier = d.get("die_count_modifier", 0)
	p.extra_rerolls_available = d.get("extra_rerolls_available", 0)
	p.has_free_reroll_after_max = d.get("has_free_reroll_after_max", false)
	p.free_reroll_threes = d.get("free_reroll_threes", false)
	p.pending_die_penalty = d.get("pending_die_penalty", 0)
	p.repeat_turn_used = d.get("repeat_turn_used", false)
	p.war_drums_triggered = d.get("war_drums_triggered", false)
	p.poison_stacks = d.get("poison_stacks", 0)
	p.shrink_stacks = d.get("shrink_stacks", 0)
	p.camouflage_active = d.get("camouflage_active", false)
	p.nimble_dodge_used_this_turn = d.get("nimble_dodge_used_this_turn", false)
	p.nimble_dodge_active = d.get("nimble_dodge_active", false)
	p.die_picker_used_this_turn = d.get("die_picker_used_this_turn", false)
	p.die_jacker_used_this_turn = d.get("die_jacker_used_this_turn", false)
	p.die_jacker_pending = d.get("die_jacker_pending", false)
	return p

# ── Card token resolution ─────────────────────────────────────────────────────

static func _cards_to_array(cards: Array[CardData]) -> Array:
	var out: Array = []
	for c in cards:
		out.append({ "name": c.card_name, "charges": c.charges })
	return out

static func _cards_from_array(arr: Array) -> Array[CardData]:
	var index := _cards_by_name()
	var out: Array[CardData] = []
	for entry in arr:
		var src: CardData = index.get(entry.get("name", ""))
		if src == null:
			continue
		var card: CardData = src.duplicate()
		card.charges = entry.get("charges", 0)
		out.append(card)
	return out

static func _cards_by_name() -> Dictionary:
	if _card_index.is_empty():
		for c in CardCatalog.load_all_cards():
			_card_index[c.card_name] = c
	return _card_index

static func _env_by_name(card_name: String) -> EnvironmentEffect:
	if card_name.is_empty():
		return null
	if _env_index.is_empty():
		for c in EnvironmentDeck.load_all():
			_env_index[c.card_name] = c
	var src: EnvironmentEffect = _env_index.get(card_name)
	return src.duplicate() if src != null else null
