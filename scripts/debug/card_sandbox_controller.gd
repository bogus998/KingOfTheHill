class_name CardSandboxController
extends Control

const FACE_NAMES: Dictionary = {
	DiceResolver.DieFace.ONE: "1", DiceResolver.DieFace.TWO: "2",
	DiceResolver.DieFace.THREE: "3", DiceResolver.DieFace.GOLD: "GOLD",
	DiceResolver.DieFace.CLAW: "CLAW", DiceResolver.DieFace.HEART: "HEART"
}

var _effect_handler: CardEffectHandler
var _cards: Array[CardData] = []
var _card_option: OptionButton
var _player_option: OptionButton
var _log: RichTextLabel
var _states_container: VBoxContainer
var _damage_spin: SpinBox
var _heal_spin: SpinBox
var _roll_spin: SpinBox
var _card_desc_label: Label


func _ready() -> void:
	_effect_handler = CardEffectHandler.new()

	_build_ui()
	_connect_autoload_signals()
	_setup_players()
	_load_cards()


func _setup_players() -> void:
	PlayerManager.setup([{"name": "Alice"}, {"name": "Bob"}])
	PlayerManager.add_gold(0, 20)
	PlayerManager.add_gold(1, 20)


func _connect_autoload_signals() -> void:
	TurnManager.turn_started.connect(_effect_handler._on_turn_started)
	TurnManager.turn_ended.connect(_effect_handler._on_turn_ended)
	PlayerManager.damage_applied.connect(_effect_handler._on_damage_applied)
	PlayerManager.player_eliminated.connect(_effect_handler._on_player_eliminated)
	PlayerManager.position_changed.connect(_effect_handler._on_position_changed)
	_effect_handler.mimic_ui_needed.connect(func(_idx): _log_line("Mimic auto-resolved"))

	PlayerManager.player_damaged.connect(func(_i, _hp): _refresh_states())
	PlayerManager.player_healed.connect(func(_i, _hp): _refresh_states())
	PlayerManager.gem_changed.connect(func(_i, _g): _refresh_states())
	PlayerManager.gold_changed.connect(func(_i, _g): _refresh_states())
	PlayerManager.card_hand_changed.connect(func(_i): _refresh_states())
	PlayerManager.players_setup.connect(_refresh_states)


func _build_ui() -> void:
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hbox)

	# Left: controls
	var controls := VBoxContainer.new()
	controls.custom_minimum_size.x = 300
	hbox.add_child(controls)

	_card_option = OptionButton.new()
	_player_option = OptionButton.new()
	_player_option.add_item("Alice")
	_player_option.add_item("Bob")

	controls.add_child(_make_label("Card:"))
	controls.add_child(_card_option)
	_card_desc_label = Label.new()
	_card_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_desc_label.custom_minimum_size.y = 40
	controls.add_child(_card_desc_label)
	_card_option.item_selected.connect(_on_card_selected)
	controls.add_child(_make_label("Target:"))
	controls.add_child(_player_option)

	var apply_btn := Button.new()
	apply_btn.text = "Apply Card"
	apply_btn.pressed.connect(_on_apply_card)
	controls.add_child(apply_btn)

	controls.add_child(HSeparator.new())
	controls.add_child(_make_label("Turn Events:"))

	var turn_hbox := HBoxContainer.new()
	var turn_start_btn := Button.new()
	turn_start_btn.text = "Turn Start"
	turn_start_btn.pressed.connect(_on_turn_start)
	var turn_end_btn := Button.new()
	turn_end_btn.text = "Turn End"
	turn_end_btn.pressed.connect(_on_turn_end)
	turn_hbox.add_child(turn_start_btn)
	turn_hbox.add_child(turn_end_btn)
	controls.add_child(turn_hbox)

	controls.add_child(HSeparator.new())
	controls.add_child(_make_label("Direct Effects:"))

	_damage_spin = SpinBox.new()
	_damage_spin.min_value = 1
	_damage_spin.max_value = 20
	_damage_spin.value = 2
	var dmg_btn := Button.new()
	dmg_btn.text = "Deal Damage"
	dmg_btn.pressed.connect(_on_deal_damage)
	var dmg_hbox := HBoxContainer.new()
	dmg_hbox.add_child(_damage_spin)
	dmg_hbox.add_child(dmg_btn)
	controls.add_child(dmg_hbox)

	_heal_spin = SpinBox.new()
	_heal_spin.min_value = 1
	_heal_spin.max_value = 10
	_heal_spin.value = 1
	var heal_btn := Button.new()
	heal_btn.text = "Heal"
	heal_btn.pressed.connect(_on_heal)
	var heal_hbox := HBoxContainer.new()
	heal_hbox.add_child(_heal_spin)
	heal_hbox.add_child(heal_btn)
	controls.add_child(heal_hbox)

	controls.add_child(HSeparator.new())
	controls.add_child(_make_label("Roll Dice:"))

	_roll_spin = SpinBox.new()
	_roll_spin.min_value = 1
	_roll_spin.max_value = 6
	_roll_spin.value = 3
	var roll_btn := Button.new()
	roll_btn.text = "Roll"
	roll_btn.pressed.connect(_on_roll)
	var roll_hbox := HBoxContainer.new()
	roll_hbox.add_child(_roll_spin)
	roll_hbox.add_child(roll_btn)
	controls.add_child(roll_hbox)

	hbox.add_child(VSeparator.new())

	# Center: player states
	var states_box := VBoxContainer.new()
	states_box.custom_minimum_size.x = 280
	hbox.add_child(states_box)

	states_box.add_child(_make_label("Player States"))

	var reset_btn := Button.new()
	reset_btn.text = "Reset"
	reset_btn.pressed.connect(_on_reset)
	states_box.add_child(reset_btn)

	_states_container = VBoxContainer.new()
	states_box.add_child(_states_container)

	hbox.add_child(VSeparator.new())

	# Right: log
	var log_box := VBoxContainer.new()
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(log_box)

	var log_header := HBoxContainer.new()
	var log_label := _make_label("Log")
	log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_header.add_child(log_label)
	var clear_btn := Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(func(): _log.clear())
	log_header.add_child(clear_btn)
	log_box.add_child(log_header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_box.add_child(scroll)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.fit_content = true
	_log.custom_minimum_size.x = 200
	scroll.add_child(_log)

	_refresh_states()


func _load_cards() -> void:
	_cards = CardCatalog.load_all_cards()
	_card_option.clear()
	for card in _cards:
		var type_str := "ONE_TIME" if card.card_type == CardData.CardType.ONE_TIME else "PERMANENT"
		_card_option.add_item("%s [%s]" % [card.card_name, type_str])
	if not _cards.is_empty():
		_card_desc_label.text = _cards[0].description


func _on_card_selected(index: int) -> void:
	_card_desc_label.text = _cards[index].description if index < _cards.size() else ""


func _refresh_states(_arg1 = null, _arg2 = null) -> void:
	for child in _states_container.get_children():
		child.queue_free()

	for i in PlayerManager.players.size():
		var p := PlayerManager.players[i]
		var panel := PanelContainer.new()
		var vbox := VBoxContainer.new()
		panel.add_child(vbox)

		var status_line: String
		if p.is_eliminated:
			status_line = "%s  [ELIMINATED]" % p.player_name
		else:
			status_line = "%s  [HP: %d/%d  Gold: %d  Gems: %d]" % [
				p.player_name, p.health, p.max_health, p.gold, p.gems
			]
		vbox.add_child(_make_label(status_line))

		if not p.cards_in_hand.is_empty():
			var card_names := p.cards_in_hand.map(func(c): return c.card_name)
			vbox.add_child(_make_label("Cards: " + ", ".join(card_names)))

		var statuses: Array[String] = []
		if p.poison_stacks > 0:
			statuses.append("poison:%d" % p.poison_stacks)
		if p.shrink_stacks > 0:
			statuses.append("shrink:%d" % p.shrink_stacks)
		if p.camouflage_active:
			statuses.append("camouflage")
		if p.gold_dodge_active:
			statuses.append("gold_dodge")
		if not statuses.is_empty():
			vbox.add_child(_make_label("Status: " + "  ".join(statuses)))

		_states_container.add_child(panel)


func _selected_player_index() -> int:
	return _player_option.selected


func _on_apply_card() -> void:
	if _cards.is_empty() or _card_option.selected < 0:
		return
	var idx := _selected_player_index()
	var card := _cards[_card_option.selected]
	if card.card_type == CardData.CardType.PERMANENT:
		PlayerManager.add_card_to_hand(idx, card)
	_effect_handler._on_card_purchased(idx, card)
	_log_line("Applied [%s] to %s" % [card.card_name, PlayerManager.players[idx].player_name])


func _on_turn_start() -> void:
	var idx := _selected_player_index()
	TurnManager.current_player_index = idx
	TurnManager.turn_started.emit(idx)
	_log_line("Turn Start → %s" % PlayerManager.players[idx].player_name)


func _on_turn_end() -> void:
	var idx := _selected_player_index()
	TurnManager.turn_ended.emit(idx)
	_log_line("Turn End → %s" % PlayerManager.players[idx].player_name)


func _on_deal_damage() -> void:
	var idx := _selected_player_index()
	var amount := int(_damage_spin.value)
	PlayerManager.apply_damage(idx, amount)
	_log_line("Dealt %d damage to %s" % [amount, PlayerManager.players[idx].player_name])


func _on_heal() -> void:
	var idx := _selected_player_index()
	var amount := int(_heal_spin.value)
	PlayerManager.apply_heal(idx, amount)
	_log_line("Healed %d HP on %s" % [amount, PlayerManager.players[idx].player_name])


func _on_roll() -> void:
	var idx := _selected_player_index()
	var count := int(_roll_spin.value)
	var faces: Array = []
	for _i in count:
		faces.append(randi_range(1, 6) as DiceResolver.DieFace)
	_effect_handler.on_roll_finalized(idx, faces)
	var face_strs := faces.map(func(f): return FACE_NAMES.get(f, str(f)))
	_log_line("Roll (%s): [%s]" % [PlayerManager.players[idx].player_name, ", ".join(face_strs)])


func _on_reset() -> void:
	_setup_players()
	_log_line("─── Reset ───")


func _log_line(text: String) -> void:
	var time := Time.get_time_string_from_system()
	_log.append_text("[%s] %s\n" % [time, text])
	await get_tree().process_frame
	var scroll := _log.get_parent() as ScrollContainer
	if scroll:
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value


func _make_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return lbl


func _exit_tree() -> void:
	TurnManager.turn_started.disconnect(_effect_handler._on_turn_started)
	TurnManager.turn_ended.disconnect(_effect_handler._on_turn_ended)
	PlayerManager.damage_applied.disconnect(_effect_handler._on_damage_applied)
	PlayerManager.player_eliminated.disconnect(_effect_handler._on_player_eliminated)
	PlayerManager.position_changed.disconnect(_effect_handler._on_position_changed)
