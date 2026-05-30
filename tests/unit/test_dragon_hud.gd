extends GutTest

var _hud: DragonHUD

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})
	_hud = add_child_autofree(DragonHUD.new())

func after_each() -> void:
	EnvironmentManager.active_card = null
	EnvironmentManager.pending_card = null

# ── Rage meter ────────────────────────────────────────────────────────────────

func test_rage_label_shows_value_and_threshold() -> void:
	assert_string_contains(_hud._rage_label.text, "0 / 5")   # 2P first threshold

func test_rage_bar_max_matches_threshold() -> void:
	assert_eq(_hud._rage_bar.max_value, 5.0)

# ── Awakening warning ─────────────────────────────────────────────────────────

func test_warning_hidden_initially() -> void:
	assert_false(_hud._warning.visible)

func test_warning_shows_on_pending() -> void:
	DragonManager.awakening_pending.emit()
	assert_true(_hud._warning.visible)

func test_warning_hidden_on_new_game() -> void:
	DragonManager.awakening_pending.emit()
	PlayerManager.players_setup.emit()
	assert_false(_hud._warning.visible)

# ── Environment banner ────────────────────────────────────────────────────────

func test_env_banner_shows_on_activation() -> void:
	var card := DroughtEffect.new()
	card.card_name = "Drought"
	card.description = "All cards in the shop cost +1 this round."
	EnvironmentManager.card_activated.emit(card)
	assert_true(_hud._env_banner.visible)
	assert_string_contains(_hud._env_banner.text, "Drought")

func test_env_banner_hidden_on_dismiss() -> void:
	EnvironmentManager.card_activated.emit(DroughtEffect.new())
	EnvironmentManager.card_dismissed.emit(null)
	assert_false(_hud._env_banner.visible)

# ── Awakening outcome description ──────────────────────────────────────────────

func test_describe_fire() -> void:
	var text := _hud._describe({"action": DragonDice.Action.FIRE, "fire": 2})
	assert_string_contains(text, "2 damage")

func test_describe_slumber() -> void:
	var text := _hud._describe({"action": DragonDice.Action.SLUMBER})
	assert_string_contains(text, "sleep")

func test_describe_environment_names_drawn_card() -> void:
	var card := DroughtEffect.new()
	card.card_name = "Drought"
	EnvironmentManager.pending_card = card
	var text := _hud._describe({"action": DragonDice.Action.ENVIRONMENT})
	assert_string_contains(text, "Drought")

# ── Dragon avatar ─────────────────────────────────────────────────────────────

func test_dragon_starts_asleep() -> void:
	assert_string_contains(_hud._dragon_label.text, "dragon")

func test_dragon_marked_awake_on_start() -> void:
	_hud._on_awakening_started()
	assert_string_contains(_hud._dragon_label.text, "DRAGON")
