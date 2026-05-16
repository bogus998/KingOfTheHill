extends Control

const _CARD_DISPLAY = preload("res://scenes/cards/card_display.tscn")

@onready var _title_label: Label = $Background/VBoxContainer/TitleLabel
@onready var _cards_container: HBoxContainer = $Background/VBoxContainer/CardsScroll/CardsContainer
@onready var _close_button: Button = $Background/VBoxContainer/CloseButton

func _ready() -> void:
	_close_button.pressed.connect(func(): visible = false)

func show_for_player(idx: int) -> void:
	if idx >= PlayerManager.players.size():
		return
	var p := PlayerManager.players[idx]
	_title_label.text = "%s's Cards" % p.player_name
	for child in _cards_container.get_children():
		child.queue_free()
	for card in p.cards_in_hand:
		var display = _CARD_DISPLAY.instantiate()
		_cards_container.add_child(display)
		display.refresh(card, -1)
		display.set_buy_visible(false)
	for card in p.spent_one_time_cards:
		var display = _CARD_DISPLAY.instantiate()
		_cards_container.add_child(display)
		display.refresh(card, -1)
		display.set_buy_visible(false)
		display.modulate = Color(0.5, 0.5, 0.5)
	visible = true
