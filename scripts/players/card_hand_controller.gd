extends PanelContainer

@onready var _cards_container: HBoxContainer = $VBox/CardsContainer

func _ready() -> void:
	PlayerManager.card_hand_changed.connect(_on_card_hand_changed)
	GameManager.game_started.connect(_refresh)
	TurnManager.turn_started.connect(func(_idx): _refresh())

func _on_card_hand_changed(idx: int) -> void:
	if idx == TurnManager.current_player_index:
		_refresh()

func _refresh() -> void:
	for child in _cards_container.get_children():
		child.queue_free()
	if TurnManager.current_player_index >= PlayerManager.players.size():
		return
	for card in PlayerManager.players[TurnManager.current_player_index].cards_in_hand:
		var label := Label.new()
		label.text = card.card_name
		label.tooltip_text = "%s\n💎%d — %s" % [card.card_name, card.gem_cost, card.description]
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		_cards_container.add_child(label)
