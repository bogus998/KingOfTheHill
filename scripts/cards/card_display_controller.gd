extends PanelContainer

signal buy_pressed(slot_index: int)

@export var slot_index: int = 0

@onready var _name_label: Label = $VBox/NameLabel
@onready var _cost_label: Label = $VBox/CostLabel
@onready var _desc_label: Label = $VBox/DescLabel
@onready var _buy_button: Button = $VBox/BuyButton

func refresh(card: CardData, player_gems: int) -> void:
	if card == null:
		visible = false
		return
	visible = true
	_name_label.text = card.card_name
	_cost_label.text = "💎 %d" % card.gem_cost
	_desc_label.text = card.description
	_buy_button.disabled = player_gems < card.gem_cost

func _on_buy_button_pressed() -> void:
	buy_pressed.emit(slot_index)
