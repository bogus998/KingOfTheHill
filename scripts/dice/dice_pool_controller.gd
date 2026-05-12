extends Node

signal roll_completed(faces: Array)

const MAX_ROLLS := 3

var _dice: Array = []
var _roll_count: int = 0

@onready var _roll_button: Button = $RollButton
@onready var _dice_container: HBoxContainer = $DiceContainer

func _ready() -> void:
	_roll_button.pressed.connect(_on_roll_pressed)
	TurnManager.turn_started.connect(_on_turn_started)
	for child in _dice_container.get_children():
		_dice.append(child)

func roll_active_dice() -> void:
	if _roll_count >= MAX_ROLLS:
		return
	for die in _dice:
		die.roll()
	_roll_count += 1
	TurnManager.roll_count = _roll_count
	if _roll_count >= MAX_ROLLS:
		_roll_button.disabled = true
	emit_signal("roll_completed", get_all_faces())

func toggle_hold(die_index: int) -> void:
	if die_index >= 0 and die_index < _dice.size():
		_dice[die_index].toggle_hold()

func get_die(die_index: int) -> Node:
	if die_index >= 0 and die_index < _dice.size():
		return _dice[die_index]
	return null

func get_dice_count() -> int:
	return _dice.size()

func get_all_faces() -> Array:
	var faces: Array = []
	for die in _dice:
		faces.append(die.face)
	return faces

func _on_roll_pressed() -> void:
	roll_active_dice()

func _on_turn_started(_player_index: int) -> void:
	_roll_count = 0
	_roll_button.disabled = false
