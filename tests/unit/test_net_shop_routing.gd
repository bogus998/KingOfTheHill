extends GutTest

## LAN action routing: the shop panel emits buy/refresh as intents (it no longer
## mutates CardShop directly). main_game_controller forwards them to the host on a
## client, or dispatches them locally. See dice_pool_controller's roll_requested.

var _shop: CardShopController = null

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})
	_shop = add_child_autofree(preload("res://scenes/cards/card_shop.tscn").instantiate())

func test_buy_press_emits_buy_card_requested_with_slot() -> void:
	var captured: Array = []
	_shop.buy_card_requested.connect(func(slot): captured.append(slot))
	_shop._on_buy_pressed(1)
	assert_eq(captured, [1], "buy intent carries the pressed slot index")

func test_buy_press_does_not_mutate_shop_directly() -> void:
	var gold_before: int = PlayerManager.players[0].gold
	_shop._on_buy_pressed(0)
	assert_eq(PlayerManager.players[0].gold, gold_before,
			"buying is now an intent; the host executor mutates state, not the panel")

func test_refresh_press_emits_refresh_shop_requested() -> void:
	watch_signals(_shop)
	_shop._on_refresh_pressed()
	assert_signal_emitted(_shop, "refresh_shop_requested")
