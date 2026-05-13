extends PanelContainer

@onready var _slot0 = $VBox/Slots/Slot0
@onready var _slot1 = $VBox/Slots/Slot1
@onready var _slot2 = $VBox/Slots/Slot2
@onready var _refresh_button: Button = $VBox/RefreshButton

func _ready() -> void:
	_slot0.buy_pressed.connect(_on_buy_pressed)
	_slot1.buy_pressed.connect(_on_buy_pressed)
	_slot2.buy_pressed.connect(_on_buy_pressed)
	_refresh_button.pressed.connect(_on_refresh_pressed)
	CardShop.shop_updated.connect(_on_shop_updated)
	TurnManager.phase_changed.connect(_on_phase_changed)
	GameManager.game_started.connect(_refresh_display)
	_on_phase_changed(TurnManager.current_phase)

func _on_buy_pressed(slot_index: int) -> void:
	CardShop.purchase(slot_index, TurnManager.current_player_index)

func _on_refresh_pressed() -> void:
	CardShop.refresh_pool(TurnManager.current_player_index)

func _on_shop_updated(_cards: Array) -> void:
	_refresh_display()

func _refresh_display() -> void:
	if PlayerManager.players.is_empty():
		return
	var gems: int = PlayerManager.players[TurnManager.current_player_index].gems
	var slots := [_slot0, _slot1, _slot2]
	for i in slots.size():
		var card: CardData = CardShop.visible_cards[i] if i < CardShop.visible_cards.size() else null
		slots[i].refresh(card, gems)
	_refresh_button.disabled = gems < CardShop.REFRESH_COST

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	visible = (phase == TurnManager.TurnPhase.BUY_CARDS)
	if phase == TurnManager.TurnPhase.BUY_CARDS:
		_refresh_display()
