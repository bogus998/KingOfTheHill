extends GutTest

func _build_hud(player_count: int) -> Control:
	var configs: Array[Dictionary] = []
	for i in player_count:
		configs.append({"name": "P%d" % i, "is_bot": false})
	PlayerManager.setup(configs)
	var hud: Control = add_child_autofree(load("res://scenes/ui/hud.tscn").instantiate())
	GameManager.game_started.emit()
	return hud

func _panel_count(hud: Control) -> int:
	return hud.get_node("PlayersLeft").get_child_count() \
		+ hud.get_node("PlayersRight").get_child_count()

func test_hud_shows_2_panels_for_2_players() -> void:
	assert_eq(_panel_count(_build_hud(2)), 2)

func test_hud_shows_3_panels_for_3_players() -> void:
	assert_eq(_panel_count(_build_hud(3)), 3)

func test_hud_shows_4_panels_for_4_players() -> void:
	assert_eq(_panel_count(_build_hud(4)), 4)

func test_hud_splits_panels_around_vault() -> void:
	var hud := _build_hud(3)
	assert_eq(hud.get_node("PlayersLeft").get_child_count(), 2)
	assert_eq(hud.get_node("PlayersRight").get_child_count(), 1)
