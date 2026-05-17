extends PanelContainer

signal buy_pressed(slot_index: int)

@export var slot_index: int = 0

@onready var _icon: TextureRect = $VBox/Icon
@onready var _name_label: Label = $VBox/NameLabel
@onready var _cost_label: Label = $VBox/CostLabel
@onready var _desc_label: Label = $VBox/DescLabel
@onready var _buy_button: Button = $VBox/BuyButton

func refresh(card: CardData, player_gold: int, display_cost: int = -1) -> void:
	if card == null:
		visible = false
		return
	visible = true
	_icon.texture = card.card_icon
	_icon.visible = card.card_icon != null
	_name_label.text = card.card_name
	var cost := card.gold_cost if display_cost < 0 else display_cost
	_cost_label.text = "🪙 %d" % cost
	_desc_label.text = card.description
	_buy_button.disabled = player_gold < cost

func set_buy_visible(value: bool) -> void:
	_buy_button.visible = value

func _on_buy_button_pressed() -> void:
	buy_pressed.emit(slot_index)
