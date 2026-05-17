extends GutTest

var _pool: Node = null

func before_each() -> void:
	GameManager.start_game({"players": [
		{"name": "Thorin", "is_bot": false},
		{"name": "Gimli",  "is_bot": false},
	]})
	_pool = add_child_autofree(preload("res://scenes/dice/dice_pool.tscn").instantiate())

# ── Initial state ─────────────────────────────────────────────────────────────

func test_pool_has_6_dice() -> void:
	assert_eq(_pool.get_dice_count(), 6)

func test_all_dice_start_active() -> void:
	for i in 6:
		assert_eq(_pool.get_die(i).state, _pool.get_die(i).DieState.ACTIVE)

# ── Rolling ───────────────────────────────────────────────────────────────────

func test_held_dice_unchanged_after_roll() -> void:
	for i in 6:
		_pool.toggle_hold(i)
	var before: Array = _pool.get_all_faces().duplicate()
	_pool.roll_active_dice()
	assert_eq(_pool.get_all_faces(), before)

func test_held_die_keeps_face_after_pool_roll() -> void:
	_pool.get_die(0).set_face(DiceResolver.DieFace.HEART)
	_pool.toggle_hold(0)
	_pool.roll_active_dice()
	assert_eq(_pool.get_die(0).face, DiceResolver.DieFace.HEART)

func test_roll_emits_roll_completed() -> void:
	watch_signals(_pool)
	_pool.roll_active_dice()
	assert_signal_emitted(_pool, "roll_completed")

func test_roll_completed_carries_6_faces() -> void:
	var captured: Array = []
	_pool.roll_completed.connect(func(faces): captured.assign(faces))
	_pool.roll_active_dice()
	assert_eq(captured.size(), 6)

# ── Hold mechanics ────────────────────────────────────────────────────────────

func test_toggle_hold_sets_die_to_held() -> void:
	_pool.toggle_hold(0)
	assert_eq(_pool.get_die(0).state, _pool.get_die(0).DieState.HELD)

func test_toggle_hold_twice_returns_to_active() -> void:
	_pool.toggle_hold(0)
	_pool.toggle_hold(0)
	assert_eq(_pool.get_die(0).state, _pool.get_die(0).DieState.ACTIVE)

func test_get_all_faces_returns_6_elements() -> void:
	assert_eq(_pool.get_all_faces().size(), 6)

# ── Hold gating (dice not holdable before first roll) ─────────────────────────

func test_dice_not_holdable_before_first_roll() -> void:
	for i in 6:
		assert_false(_pool.get_die(i)._holdable)

func test_dice_become_holdable_after_first_roll() -> void:
	_pool.roll_active_dice()
	for i in 6:
		assert_true(_pool.get_die(i)._holdable)

func test_dice_not_holdable_after_reset_hold() -> void:
	_pool.roll_active_dice()
	for i in 6:
		_pool.get_die(i).reset_hold()
		assert_false(_pool.get_die(i)._holdable)

func test_gui_click_ignored_before_first_roll() -> void:
	var die: Node = _pool.get_die(0)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	die._gui_input(event)
	assert_eq(die.state, die.DieState.ACTIVE)

func test_gui_click_holds_die_after_first_roll() -> void:
	_pool.roll_active_dice()
	var die: Node = _pool.get_die(0)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	die._gui_input(event)
	assert_eq(die.state, die.DieState.HELD)

func test_holdable_remains_true_on_subsequent_rolls() -> void:
	_pool.roll_active_dice()
	_pool.roll_active_dice()
	for i in 6:
		assert_true(_pool.get_die(i)._holdable)
