class_name DicePoolController
extends VBoxContainer

signal roll_completed(faces: Array)
signal end_roll_requested

const BASE_DIE_COUNT := 6

var _dice: Array[DieController] = []
var _roll_count: int = 0
var _forced_reroll_pending: bool = false

@onready var _roll_button: Button = $RollButton
@onready var _dice_container: HBoxContainer = $DiceContainer
@onready var _end_round_btn: Button = $EndRoundButton

func _ready() -> void:
	_roll_button.pressed.connect(_on_roll_pressed)
	_end_round_btn.pressed.connect(func(): end_roll_requested.emit())
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.phase_changed.connect(_on_phase_changed)
	for child in _dice_container.get_children():
		_dice.append(child)

func get_max_rolls() -> int:
	var p := PlayerManager.players[TurnManager.current_player_index]
	var base := 3 + p.extra_rerolls_available
	if EnvironmentManager.grants_free_reroll():
		base += 1
	var limit := EnvironmentManager.roll_limit()
	if limit >= 0:
		return mini(base, limit)
	return base

func roll_active_dice() -> void:
	if _roll_count >= get_max_rolls():
		return
	for die in _dice:
		if die.visible:
			die.roll()
	_roll_count += 1
	TurnManager.roll_count = _roll_count
	if _roll_count == 1:
		for die in _dice:
			if die.visible:
				die.set_holdable(true)
		_apply_die_jacker()
	_end_round_btn.disabled = false
	_apply_shadow_runner()
	_update_roll_button()
	roll_completed.emit(get_all_faces())

func toggle_hold(die_index: int) -> void:
	if die_index >= 0 and die_index < _dice.size():
		_dice[die_index].toggle_hold()

func get_die(die_index: int) -> DieController:
	if die_index >= 0 and die_index < _dice.size():
		return _dice[die_index]
	return null

func get_dice_count() -> int:
	var count := 0
	for die in _dice:
		if die.visible:
			count += 1
	return count

func get_all_faces() -> Array:
	var faces: Array = []
	for die in _dice:
		if die.visible:
			faces.append(die.face)
	return faces

func enter_die_selection_mode(callback: Callable) -> void:
	cancel_die_selection()
	for i in _dice.size():
		var die := _dice[i]
		if not die.visible:
			continue
		die.set_holdable(false)
		var idx := i
		die.pressed.connect(func():
			_exit_die_selection_mode()
			callback.call(idx)
		, CONNECT_ONE_SHOT)

func cancel_die_selection() -> void:
	_exit_die_selection_mode()

func set_forced_reroll_pending(value: bool) -> void:
	_forced_reroll_pending = value

func _exit_die_selection_mode() -> void:
	for die in _dice:
		if not die.visible:
			continue
		for conn in die.pressed.get_connections():
			die.pressed.disconnect(conn["callable"])
		if _roll_count > 0:
			die.set_holdable(true)

func _on_roll_pressed() -> void:
	var p := PlayerManager.players[TurnManager.current_player_index]
	if _roll_count >= get_max_rolls() and p.has_free_reroll_after_max:
		p.has_free_reroll_after_max = false
		_do_free_reroll()
	else:
		roll_active_dice()

func _do_free_reroll() -> void:
	for die in _dice:
		if die.visible and die.state != DieController.DieState.HELD:
			die.roll()
	_apply_shadow_runner()
	_update_roll_button()
	roll_completed.emit(get_all_faces())

func _apply_shadow_runner() -> void:
	var p := PlayerManager.players[TurnManager.current_player_index]
	if not p.free_reroll_threes:
		return
	for die in _dice:
		if die.visible and die.face == DiceResolver.DieFace.THREE:
			die.reset_hold()

func _update_roll_button() -> void:
	var p := PlayerManager.players[TurnManager.current_player_index]
	var at_max := _roll_count >= get_max_rolls()
	var has_unheld_threes := false
	if p.free_reroll_threes:
		for die in _dice:
			if die.visible and die.face == DiceResolver.DieFace.THREE:
				has_unheld_threes = true
				break
	if not at_max or has_unheld_threes:
		_roll_button.disabled = false
		_roll_button.text = "Roll"
	elif p.has_free_reroll_after_max:
		_roll_button.disabled = false
		_roll_button.text = "Free Reroll"
	else:
		_roll_button.disabled = true
		_roll_button.text = "Roll"

func _update_die_visibility() -> void:
	var p := PlayerManager.players[TurnManager.current_player_index]
	var penalty: int = p.pending_die_penalty
	p.pending_die_penalty = 0
	var target := clampi(BASE_DIE_COUNT + p.die_count_modifier - penalty + EnvironmentManager.dice_count_delta(), 1, _dice.size())
	for i in _dice.size():
		_dice[i].visible = i < target

func _apply_die_jacker() -> void:
	if not _forced_reroll_pending:
		return
	_forced_reroll_pending = false
	var active: Array[DieController] = []
	for die in _dice:
		if die.visible and die.state == DieController.DieState.ACTIVE:
			active.append(die)
	if not active.is_empty():
		active[randi() % active.size()].roll()

func _on_turn_started(_player_index: int) -> void:
	_roll_count = 0
	_roll_button.disabled = false
	_roll_button.text = "Roll"
	_end_round_btn.disabled = true
	_end_round_btn.visible = false
	for die in _dice:
		die.reset_hold()
	_update_die_visibility.call_deferred()

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	_end_round_btn.visible = (phase == TurnManager.TurnPhase.DICE_ROLL)
