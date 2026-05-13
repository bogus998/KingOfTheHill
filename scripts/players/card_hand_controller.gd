extends PanelContainer

@export var player_index: int = 0

@onready var _cards_container: HBoxContainer = $VBox/CardsContainer

func _ready() -> void:
	PlayerManager.card_hand_changed.connect(_on_card_hand_changed)
	GameManager.game_started.connect(_refresh)

func _on_card_hand_changed(idx: int) -> void:
	if idx == player_index:
		_refresh()

func _refresh() -> void:
	for child in _cards_container.get_children():
		child.queue_free()
	if player_index >= PlayerManager.players.size():
		return
	for card in PlayerManager.players[player_index].cards_in_hand:
		var label := Label.new()
		label.text = card.card_name
		_cards_container.add_child(label)
