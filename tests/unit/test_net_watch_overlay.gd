extends GutTest

## WatchOverlay: shown only in multiplayer, only when it isn't this device's turn.
## It eats input so a watcher can't drive someone else's turn.

var _overlay: WatchOverlay = null

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})
	_overlay = add_child_autofree(WatchOverlay.new())

func after_each() -> void:
	# Leave the shared autoloads in their default single-player state.
	NetworkManager.mode = NetworkManager.Mode.SINGLE
	NetworkManager.my_player_id = 0
	TurnManager.current_player_index = 0

func test_hidden_in_single_player() -> void:
	NetworkManager.mode = NetworkManager.Mode.SINGLE
	TurnManager.current_player_index = 1
	_overlay.refresh()
	assert_false(_overlay.visible, "hot-seat uses the pass-device screen, not this overlay")

func test_hidden_on_my_turn() -> void:
	NetworkManager.mode = NetworkManager.Mode.HOST
	NetworkManager.my_player_id = 0
	TurnManager.current_player_index = 0
	_overlay.refresh()
	assert_false(_overlay.visible, "my own turn is interactive")

func test_visible_when_watching_another_player() -> void:
	NetworkManager.mode = NetworkManager.Mode.HOST
	NetworkManager.my_player_id = 0
	TurnManager.current_player_index = 1
	_overlay.refresh()
	assert_true(_overlay.visible, "another player's turn is watch-only")

func test_input_is_blocked_while_visible() -> void:
	NetworkManager.mode = NetworkManager.Mode.CLIENT
	NetworkManager.my_player_id = 1
	TurnManager.current_player_index = 0
	_overlay.refresh()
	assert_true(_overlay.visible)
	assert_eq(_overlay.mouse_filter, Control.MOUSE_FILTER_STOP,
			"the overlay swallows touches so a watcher can't act")
