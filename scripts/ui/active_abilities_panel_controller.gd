class_name ActiveAbilitiesPanelController
extends VBoxContainer

signal ability_used(effect_id: CardEffectId.Id, player_index: int)

var _rows: Array[Dictionary] = []

func _ready() -> void:
	TurnManager.turn_started.connect(_rebuild_rows)
	TurnManager.phase_changed.connect(_on_phase_changed)
	PlayerManager.gold_changed.connect(func(_p: int, _g: int): _update_buttons())
	PlayerManager.card_hand_changed.connect(func(idx: int) -> void:
		if not PlayerManager.players.is_empty() and idx == TurnManager.current_player_index:
			_rebuild_rows(idx))
	visible = false

func _rebuild_rows(player_idx: int) -> void:
	for child in get_children():
		child.queue_free()
	_rows.clear()

	if PlayerManager.players[player_idx].is_bot:
		visible = false
		return

	var p := PlayerManager.players[player_idx]
	var seen_ids: Array[CardEffectId.Id] = []
	for card in p.cards_in_hand:
		if card.effect == null:
			continue
		var eid: CardEffectId.Id = card.effect.effect_id
		var is_gold_ability: bool = _is_gold_active_effect(eid)
		var is_actionable: bool = card.card_type == CardData.CardType.ACTIONABLE
		if not (is_gold_ability or is_actionable) or seen_ids.has(eid):
			continue
		seen_ids.append(eid)
		_rows.append(_make_row(eid, player_idx, is_actionable))

	_on_phase_changed(TurnManager.current_phase)

func _make_row(eid: CardEffectId.Id, player_idx: int, is_actionable: bool) -> Dictionary:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = _effect_name(eid) if is_actionable else "%s [%d🪙]" % [_effect_name(eid), _effect_cost(eid)]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var btn := Button.new()
	btn.text = "USE"
	btn.custom_minimum_size = Vector2(80, 56)
	btn.pressed.connect(func(): ability_used.emit(eid, player_idx))
	hbox.add_child(lbl)
	hbox.add_child(btn)
	add_child(hbox)
	return { "effect_id": eid, "row": hbox, "button": btn, "is_actionable": is_actionable }

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	var any_visible: bool = false
	for row in _rows:
		var show: bool = _is_available_in_phase(row["effect_id"], phase)
		row["row"].visible = show
		if show:
			any_visible = true
	visible = any_visible
	if any_visible:
		_update_buttons()

func _update_buttons() -> void:
	if PlayerManager.players.is_empty():
		return
	var p := PlayerManager.players[TurnManager.current_player_index]
	for row in _rows:
		if row.get("is_actionable", false):
			row["button"].disabled = false
		else:
			var eid: CardEffectId.Id = row["effect_id"]
			var turn_capped: bool = eid == CardEffectId.Id.NIMBLE_DODGE and p.nimble_dodge_used_this_turn
			row["button"].disabled = p.gold < _effect_cost(eid) or turn_capped

func _is_gold_active_effect(eid: CardEffectId.Id) -> bool:
	return eid in [CardEffectId.Id.RAPID_HEALING, CardEffectId.Id.NIMBLE_DODGE, CardEffectId.Id.SLOW_GRINDER]

func _is_available_in_phase(eid: CardEffectId.Id, phase: TurnManager.TurnPhase) -> bool:
	match eid:
		CardEffectId.Id.RAPID_HEALING, CardEffectId.Id.NIMBLE_DODGE:
			return phase == TurnManager.TurnPhase.RESOLUTION or phase == TurnManager.TurnPhase.BUY_CARDS
		CardEffectId.Id.SLOW_GRINDER:
			return phase == TurnManager.TurnPhase.BUY_CARDS
		CardEffectId.Id.WILDCARD_DIE:
			return phase == TurnManager.TurnPhase.DICE_ROLL
	return false

func _effect_name(eid: CardEffectId.Id) -> String:
	match eid:
		CardEffectId.Id.RAPID_HEALING: return "Healing Flask"
		CardEffectId.Id.NIMBLE_DODGE: return "Nimble Dodge"
		CardEffectId.Id.SLOW_GRINDER: return "Slow Grinder"
		CardEffectId.Id.WILDCARD_DIE: return "Wildcard"
	return ""

func _effect_cost(eid: CardEffectId.Id) -> int:
	match eid:
		CardEffectId.Id.RAPID_HEALING: return 2
		CardEffectId.Id.NIMBLE_DODGE: return 1
		CardEffectId.Id.SLOW_GRINDER: return 3
		CardEffectId.Id.WILDCARD_DIE: return 0
	return 0
