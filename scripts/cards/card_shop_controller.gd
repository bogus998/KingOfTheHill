class_name CardShopController
extends PanelContainer

signal peek_pressed
signal buy_from_others_pressed

@onready var _slot0 = $VBox/Slots/Slot0
@onready var _slot1 = $VBox/Slots/Slot1
@onready var _slot2 = $VBox/Slots/Slot2
@onready var _refresh_button: Button = $VBox/RefreshButton
@onready var _peek_button: Button = $VBox/PeekButton
@onready var _buy_from_others_button: Button = $VBox/BuyFromOthersButton

func _ready() -> void:
	_slot0.buy_pressed.connect(_on_buy_pressed)
	_slot1.buy_pressed.connect(_on_buy_pressed)
	_slot2.buy_pressed.connect(_on_buy_pressed)
	_refresh_button.pressed.connect(_on_refresh_pressed)
	_peek_button.pressed.connect(func(): peek_pressed.emit())
	_buy_from_others_button.pressed.connect(func(): buy_from_others_pressed.emit())
	CardShop.shop_updated.connect(_on_shop_updated)
	TurnManager.phase_changed.connect(_on_phase_changed)
	GameManager.game_started.connect(_refresh_display)
	add_to_group(NetworkManager.REFRESH_GROUP)  # LAN client: redraw on host snapshot
	_on_phase_changed(TurnManager.current_phase)

## LAN client: redraw the shop from current manager state after a host snapshot.
## Visibility is phase-driven, mirroring _on_phase_changed (which won't fire on a
## client, since apply() is silent).
func refresh() -> void:
	visible = TurnManager.current_phase == TurnManager.TurnPhase.BUY_CARDS
	if visible:
		_refresh_display()

func _on_buy_pressed(slot_index: int) -> void:
	CardShop.purchase(slot_index, TurnManager.current_player_index)

func _on_refresh_pressed() -> void:
	CardShop.refresh_pool(TurnManager.current_player_index)

func _on_shop_updated(_cards: Array) -> void:
	_refresh_display()

func _refresh_display() -> void:
	if PlayerManager.players.is_empty():
		return
	var player_idx := TurnManager.current_player_index
	var gold: int = PlayerManager.players[player_idx].gold
	var discount: int = CardShop.discount_for(player_idx)
	var slots := [_slot0, _slot1, _slot2]
	for i in slots.size():
		var card: CardData = CardShop.visible_cards[i] if i < CardShop.visible_cards.size() else null
		if card != null and discount > 0:
			slots[i].refresh(card, gold, max(0, card.gold_cost - discount))
		else:
			slots[i].refresh(card, gold)
	_refresh_button.disabled = gold < CardShop.REFRESH_COST
	_peek_button.visible = _player_has(player_idx, CardEffectId.Id.PEEK_DECK) \
			and not PlayerManager.players[player_idx].is_bot
	_buy_from_others_button.visible = _player_has(player_idx, CardEffectId.Id.BUY_FROM_OTHERS) \
			and not PlayerManager.players[player_idx].is_bot

func _player_has(player_idx: int, effect_id: CardEffectId.Id) -> bool:
	for card in PlayerManager.players[player_idx].cards_in_hand:
		if card.effect != null and card.effect.effect_id == effect_id:
			return true
	return false

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	if phase == TurnManager.TurnPhase.BUY_CARDS:
		visible = true
		modulate.a = 0.0
		_refresh_display()
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 1.0, 0.3)
	else:
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.2)
		tw.tween_callback(func(): visible = false)
