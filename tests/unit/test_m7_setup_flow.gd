extends GutTest

var _setup: Control = null

func before_each() -> void:
	_setup = add_child_autofree(load("res://scenes/menus/setup_game.tscn").instantiate())

# ── Initial state ─────────────────────────────────────────────────────────────

func test_starts_with_one_player_row() -> void:
	assert_eq(_setup.get_player_count(), 1)

func test_first_row_defaults_to_human() -> void:
	assert_false(_setup.get_player_configs()[0]["is_bot"])

func test_first_row_default_name_is_player_1() -> void:
	assert_eq(_setup.get_player_configs()[0]["name"], "Player 1")

# ── add_player ────────────────────────────────────────────────────────────────

func test_add_player_increases_count() -> void:
	_setup.add_player()
	assert_eq(_setup.get_player_count(), 2)

func test_add_player_capped_at_4() -> void:
	for _i in 6:
		_setup.add_player()
	assert_eq(_setup.get_player_count(), 4)

# ── remove_player ─────────────────────────────────────────────────────────────

func test_remove_player_decreases_count() -> void:
	_setup.add_player()
	_setup.add_player()
	_setup.remove_player(1)
	assert_eq(_setup.get_player_count(), 2)

func test_cannot_remove_last_remaining_row() -> void:
	_setup.remove_player(0)
	assert_eq(_setup.get_player_count(), 1)

# ── Bot typing & default names ───────────────────────────────────────────────

func test_bot_row_default_name_is_bot_n() -> void:
	_setup.add_player()
	_setup.set_player_type(1, true)
	assert_eq(_setup.get_player_configs()[1]["name"], "bot_2")

func test_set_player_type_marks_config_as_bot() -> void:
	_setup.add_player()
	_setup.set_player_type(1, true)
	assert_true(_setup.get_player_configs()[1]["is_bot"])

func test_custom_name_is_preserved() -> void:
	_setup.set_player_name(0, "Thrain")
	assert_eq(_setup.get_player_configs()[0]["name"], "Thrain")

func test_blank_name_falls_back_to_default() -> void:
	_setup.set_player_name(0, "   ")
	assert_eq(_setup.get_player_configs()[0]["name"], "Player 1")
