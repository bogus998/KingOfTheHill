class_name CardSandboxController
extends Control

const FACE_NAMES: Dictionary = {
	DiceResolver.DieFace.ONE: "1", DiceResolver.DieFace.TWO: "2",
	DiceResolver.DieFace.THREE: "3", DiceResolver.DieFace.GOLD: "GOLD",
	DiceResolver.DieFace.CLAW: "CLAW", DiceResolver.DieFace.HEART: "HEART"
}

var _effect_handler: CardEffectHandler
var _cards: Array[CardData] = []
var _player_option: OptionButton
var _attacker_option: OptionButton
var _log: RichTextLabel
var _states_container: VBoxContainer
var _damage_spin: SpinBox
var _heal_spin: SpinBox
var _roll_spin: SpinBox
var _card_browser: Control
var _table_container: VBoxContainer
var _search_field: LineEdit
var _filter_current: int = -1  # -1 = all, 0 = ONE_TIME, 1 = PERMANENT


func _ready() -> void:
	_effect_handler = CardEffectHandler.new()
	_build_ui()
	_build_card_browser()
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
	PlayerManager.damage_applied.connect(func(_att, _tgt, _amt): _refresh_states())


func _build_ui() -> void:
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(hbox)

	# Left: controls
	var controls := VBoxContainer.new()
	controls.custom_minimum_size.x = 300
	hbox.add_child(controls)

	_player_option = OptionButton.new()
	_player_option.add_item("Alice")
	_player_option.add_item("Bob")

	controls.add_child(_make_label("Target / Defender:"))
	controls.add_child(_player_option)

	_attacker_option = OptionButton.new()
	_attacker_option.add_item("Alice")
	_attacker_option.add_item("Bob")
	_attacker_option.selected = 1
	controls.add_child(_make_label("Attacker:"))
	controls.add_child(_attacker_option)

	var browse_btn := Button.new()
	browse_btn.text = "Browse & Apply Card"
	browse_btn.pressed.connect(_on_browse_cards)
	controls.add_child(browse_btn)

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
	var atk_btn := Button.new()
	atk_btn.text = "Attack"
	atk_btn.pressed.connect(_on_attack)
	var dmg_hbox := HBoxContainer.new()
	dmg_hbox.add_child(_damage_spin)
	dmg_hbox.add_child(dmg_btn)
	dmg_hbox.add_child(atk_btn)
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


func _build_card_browser() -> void:
	_card_browser = PanelContainer.new()
	_card_browser.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card_browser.visible = false
	add_child(_card_browser)

	var vbox := VBoxContainer.new()
	_card_browser.add_child(vbox)

	# Header row
	var header := HBoxContainer.new()
	var title := _make_label("Browse Cards")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(func(): _card_browser.visible = false)
	header.add_child(close_btn)
	vbox.add_child(header)

	# Filter row
	var filter_box := HBoxContainer.new()
	var filter_lbl := Label.new()
	filter_lbl.text = "Filter:"
	filter_lbl.custom_minimum_size.x = 55
	filter_box.add_child(filter_lbl)
	for entry in [["All", -1], ["ONE_TIME", 0], ["PERMANENT", 1]]:
		var btn := Button.new()
		btn.text = entry[0]
		btn.custom_minimum_size = Vector2(90, 28)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		btn.pressed.connect(_on_filter_changed.bind(entry[1]))
		filter_box.add_child(btn)
	vbox.add_child(filter_box)

	# Search row
	var search_box := HBoxContainer.new()
	var search_lbl := Label.new()
	search_lbl.text = "Search:"
	search_lbl.custom_minimum_size.x = 55
	search_box.add_child(search_lbl)
	_search_field = LineEdit.new()
	_search_field.placeholder_text = "Search description..."
	_search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search_field.text_changed.connect(func(_t): _rebuild_card_table())
	search_box.add_child(_search_field)
	vbox.add_child(search_box)

	vbox.add_child(HSeparator.new())

	# Column headers
	var col_header := HBoxContainer.new()
	var h_name := _make_label("Name")
	h_name.custom_minimum_size.x = 200
	var h_type := _make_label("Type")
	h_type.custom_minimum_size.x = 110
	var h_desc := _make_label("Description")
	h_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_header.add_child(h_name)
	col_header.add_child(h_type)
	col_header.add_child(h_desc)
	col_header.add_child(_make_label(""))  # spacer for Trigger column
	vbox.add_child(col_header)

	vbox.add_child(HSeparator.new())

	# Scrollable table
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_table_container = VBoxContainer.new()
	_table_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_table_container)


func _on_browse_cards() -> void:
	_search_field.text = ""
	_card_browser.visible = true
	_rebuild_card_table()


func _on_filter_changed(filter: int) -> void:
	_filter_current = filter
	_rebuild_card_table()


func _rebuild_card_table() -> void:
	for child in _table_container.get_children():
		child.queue_free()

	var query := _search_field.text.strip_edges().to_lower()
	for card in _cards:
		if _filter_current != -1 and int(card.card_type) != _filter_current:
			continue
		if query != "" and not card.description.to_lower().contains(query):
			continue

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = card.card_name
		name_lbl.custom_minimum_size.x = 200
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(name_lbl)

		var type_lbl := Label.new()
		type_lbl.text = "ONE_TIME" if card.card_type == CardData.CardType.ONE_TIME else "PERMANENT"
		type_lbl.custom_minimum_size.x = 110
		row.add_child(type_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = card.description
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(desc_lbl)

		var trigger_btn := Button.new()
		trigger_btn.text = "Trigger"
		trigger_btn.custom_minimum_size.x = 90
		trigger_btn.pressed.connect(_on_trigger_card.bind(card))
		row.add_child(trigger_btn)

		_table_container.add_child(row)
		_table_container.add_child(HSeparator.new())


func _on_trigger_card(card: CardData) -> void:
	_card_browser.visible = false
	var idx := _selected_player_index()
	if card.card_type == CardData.CardType.PERMANENT:
		PlayerManager.add_card_to_hand(idx, card)
	_effect_handler._on_card_purchased(idx, card)
	_log_line("Applied [%s] to %s" % [card.card_name, PlayerManager.players[idx].player_name])


func _load_cards() -> void:
	_cards = CardCatalog.load_all_cards()


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


func _on_attack() -> void:
	var defender := _selected_player_index()
	var attacker := _attacker_option.selected
	if attacker == defender:
		_log_line("[color=yellow]Attacker and defender are the same — skipped.[/color]")
		return
	var amount := int(_damage_spin.value)
	PlayerManager.apply_damage(defender, amount, attacker)
	_log_line("Attack: %s → %s (%d dmg)" % [
		PlayerManager.players[attacker].player_name,
		PlayerManager.players[defender].player_name,
		amount
	])


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
