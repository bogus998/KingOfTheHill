class_name ActiveAbilitiesPanelController
extends VBoxContainer

signal ability_used(effect_id: CardEffectId.Id, player_index: int)

var _rows: Array[Dictionary] = []

func _ready() -> void:
	TurnManager.turn_started.connect(_rebuild_rows)
	TurnManager.phase_changed.connect(_on_phase_changed)
	PlayerManager.gold_changed.connect(func(_p: int, _g: int): _update_buttons())
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
		if not _is_active_effect(eid) or seen_ids.has(eid):
			continue
		seen_ids.append(eid)
		_rows.append(_make_row(eid, player_idx))

	_on_phase_changed(TurnManager.current_phase)

func _make_row(eid: CardEffectId.Id, player_idx: int) -> Dictionary:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "%s [%d🪙]" % [_effect_name(eid), _effect_cost(eid)]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var btn := Button.new()
	btn.text = "USE"
	btn.custom_minimum_size = Vector2(80, 56)
	btn.pressed.connect(func(): ability_used.emit(eid, player_idx))
	hbox.add_child(lbl)
	hbox.add_child(btn)
	add_child(hbox)
	return { "effect_id": eid, "row": hbox, "button": btn }

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	var any_visible := false
	for row in _rows:
		var show := _is_available_in_phase(row["effect_id"], phase)
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
		var eid: CardEffectId.Id = row["effect_id"]
		var turn_capped := eid == CardEffectId.Id.NIMBLE_DODGE and p.nimble_dodge_used_this_turn
		row["button"].disabled = p.gold < _effect_cost(eid) or turn_capped

func _is_active_effect(eid: CardEffectId.Id) -> bool:
	return eid in [CardEffectId.Id.RAPID_HEALING, CardEffectId.Id.NIMBLE_DODGE, CardEffectId.Id.SLOW_GRINDER]

func _is_available_in_phase(eid: CardEffectId.Id, phase: TurnManager.TurnPhase) -> bool:
	match eid:
		CardEffectId.Id.RAPID_HEALING, CardEffectId.Id.NIMBLE_DODGE:
			return phase == TurnManager.TurnPhase.RESOLUTION or phase == TurnManager.TurnPhase.BUY_CARDS
		CardEffectId.Id.SLOW_GRINDER:
			return phase == TurnManager.TurnPhase.BUY_CARDS
	return false

func _effect_name(eid: CardEffectId.Id) -> String:
	match eid:
		CardEffectId.Id.RAPID_HEALING: return "Healing Flask"
		CardEffectId.Id.NIMBLE_DODGE: return "Nimble Dodge"
		CardEffectId.Id.SLOW_GRINDER: return "Slow Grinder"
	return ""

func _effect_cost(eid: CardEffectId.Id) -> int:
	match eid:
		CardEffectId.Id.RAPID_HEALING: return 2
		CardEffectId.Id.NIMBLE_DODGE: return 1
		CardEffectId.Id.SLOW_GRINDER: return 3
	return 0
