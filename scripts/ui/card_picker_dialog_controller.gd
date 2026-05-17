class_name CardPickerDialogController
extends Panel

signal confirmed(selected_cards: Array[CardData])
signal cancelled

@onready var _prompt: Label = $CenterContainer/DialogBox/VBox/PromptLabel
@onready var _cards_container: VBoxContainer = $CenterContainer/DialogBox/VBox/ScrollContainer/CardsContainer
@onready var _confirm_btn: Button = $CenterContainer/DialogBox/VBox/Buttons/ConfirmButton
@onready var _cancel_btn: Button = $CenterContainer/DialogBox/VBox/Buttons/CancelButton

enum Mode { MULTI_SELECT, SINGLE_SELECT, PEEK }

var _mode: Mode = Mode.SINGLE_SELECT
var _cards: Array[CardData] = []
var _selected: Array[CardData] = []
var _peek_card: CardData = null
var _item_buttons: Dictionary = {}  # card -> Button

func _ready() -> void:
	_confirm_btn.pressed.connect(_on_confirm)
	_cancel_btn.pressed.connect(_on_cancel)

func show_recycle(player_index: int) -> void:
	_mode = Mode.MULTI_SELECT
	_prompt.text = "Select cards to sell for their gold cost:"
	_cards = []
	for card in PlayerManager.players[player_index].cards_in_hand:
		if card.card_type == CardData.CardType.PERMANENT and card.effect != null \
				and card.effect.effect_id != CardEffectId.Id.RECYCLE_CARDS:
			_cards.append(card)
	_selected = []
	_confirm_btn.text = "Sell Selected"
	_confirm_btn.disabled = false
	_cancel_btn.text = "Keep All"
	_rebuild_list(player_index)
	visible = true

func show_mimic(player_index: int) -> void:
	_mode = Mode.SINGLE_SELECT
	_prompt.text = "Copy the effect of a card this turn:"
	_cards = []
	for i in PlayerManager.players.size():
		if i == player_index or PlayerManager.players[i].is_eliminated:
			continue
		for card in PlayerManager.players[i].cards_in_hand:
			if card.card_type == CardData.CardType.PERMANENT and card.effect != null \
					and card.effect.effect_id != CardEffectId.Id.MIMIC \
					and card.effect.effect_id != CardEffectId.Id.GOLD_BATTERY:
				_cards.append(card)
	_selected = []
	_confirm_btn.text = "Copy"
	_confirm_btn.disabled = true
	_cancel_btn.text = "Skip"
	_rebuild_list(player_index)
	visible = not _cards.is_empty()

func show_buy_from_others(player_index: int) -> void:
	_mode = Mode.SINGLE_SELECT
	_prompt.text = "Buy a card from another dwarf:"
	_cards = []
	for i in PlayerManager.players.size():
		if i == player_index or PlayerManager.players[i].is_eliminated:
			continue
		for card in PlayerManager.players[i].cards_in_hand:
			if card.card_type == CardData.CardType.PERMANENT:
				_cards.append(card)
	_selected = []
	_confirm_btn.text = "Buy"
	_confirm_btn.disabled = true
	_cancel_btn.text = "Cancel"
	_rebuild_list(player_index)
	visible = not _cards.is_empty()

func show_peek(card: CardData, player_index: int) -> void:
	_mode = Mode.PEEK
	_peek_card = card
	_prompt.text = "Top card of deck:"
	_cards = [card] if card != null else []
	_selected = []
	var gold := PlayerManager.players[player_index].gold
	_confirm_btn.text = "Buy (🪙%d)" % (card.gold_cost if card != null else 0)
	_confirm_btn.disabled = card == null or gold < card.gold_cost
	_cancel_btn.text = "Pass"
	_rebuild_list(-1)
	visible = true

func show_opportunist(card: CardData, player_index: int) -> void:
	_mode = Mode.PEEK
	_peek_card = card
	_prompt.text = "New card revealed! Buy before others?"
	_cards = [card] if card != null else []
	_selected = []
	var gold := PlayerManager.players[player_index].gold
	_confirm_btn.text = "Buy (🪙%d)" % (card.gold_cost if card != null else 0)
	_confirm_btn.disabled = card == null or gold < card.gold_cost
	_cancel_btn.text = "Pass"
	_rebuild_list(-1)
	visible = true

func _rebuild_list(_owner_index: int) -> void:
	for child in _cards_container.get_children():
		child.queue_free()
	_item_buttons.clear()
	for card in _cards:
		_add_item(card)

func _add_item(card: CardData) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = card.card_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name_lbl)

	var info_lbl := Label.new()
	info_lbl.text = _info_text(card)
	row.add_child(info_lbl)

	_cards_container.add_child(panel)

	if _mode == Mode.PEEK:
		return

	var btn := Button.new()
	btn.text = "Select"
	btn.custom_minimum_size = Vector2(80, 44)
	btn.pressed.connect(_on_item_pressed.bind(card))
	row.add_child(btn)
	_item_buttons[card] = btn

func _info_text(card: CardData) -> String:
	match _mode:
		Mode.MULTI_SELECT:
			return "🪙+%d" % card.gold_cost
		Mode.SINGLE_SELECT:
			for i in PlayerManager.players.size():
				if PlayerManager.players[i].cards_in_hand.has(card):
					return PlayerManager.players[i].player_name
		Mode.PEEK:
			return "🪙%d" % card.gold_cost
	return ""

func _on_item_pressed(card: CardData) -> void:
	if _mode == Mode.SINGLE_SELECT:
		_selected = [card]
		for c in _item_buttons:
			(_item_buttons[c] as Button).text = "Select"
		(_item_buttons[card] as Button).text = "✓"
		_confirm_btn.disabled = false
	elif _mode == Mode.MULTI_SELECT:
		if _selected.has(card):
			_selected.erase(card)
			(_item_buttons[card] as Button).text = "Select"
		else:
			_selected.append(card)
			(_item_buttons[card] as Button).text = "✓"

func _on_confirm() -> void:
	if _mode == Mode.PEEK:
		confirmed.emit([_peek_card] if _peek_card != null else [])
	else:
		confirmed.emit(_selected.duplicate())
	_selected = []
	visible = false

func _on_cancel() -> void:
	cancelled.emit()
	_selected = []
	visible = false
