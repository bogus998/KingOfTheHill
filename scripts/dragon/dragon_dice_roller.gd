class_name DragonDiceRoller
extends Control
## Visual-only presentation of a dragon dice roll.
##
## No game logic: DragonManager decides the outcome (see [[dragon_manager]]); this
## node is handed the already-decided result and animates the dice settling on it.
## Faces are placeholder emoji, deliberately distinct from the player dice — final
## art replaces these later (mock per the plan).

const ACTION_FACES := {
	DragonDice.Action.FIRE: "🔥",
	DragonDice.Action.HOARD: "💰",
	DragonDice.Action.SLUMBER: "😴",
	DragonDice.Action.ENVIRONMENT: "🌍",
	DragonDice.Action.WRATH: "🐉",
}
const SPIN_TICKS := 12
const SPIN_INTERVAL := 0.06

signal roll_finished()

var _action_label: Label
var _fire_label: Label
var _hoard_label: Label

func _ready() -> void:
	var box := HBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)
	_action_label = _make_die()
	_fire_label = _make_die()
	_hoard_label = _make_die()
	box.add_child(_action_label)
	box.add_child(_fire_label)
	box.add_child(_hoard_label)
	hide()

func _make_die() -> Label:
	var l := Label.new()
	l.custom_minimum_size = Vector2(96, 96)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 48)
	l.text = "🐉"
	return l

## Animate the dice settling on the given outcome. A fire/hoard value of 0 hides
## that magnitude die. Awaitable; emits `roll_finished` when settled.
func play(action: int, fire: int, hoard: int) -> void:
	show()
	_fire_label.visible = fire > 0
	_hoard_label.visible = hoard > 0
	var faces: Array = ACTION_FACES.values()
	for _tick in SPIN_TICKS:
		_action_label.text = faces[randi() % faces.size()]
		if _fire_label.visible:
			_fire_label.text = str(randi() % 3 + 1)
		if _hoard_label.visible:
			_hoard_label.text = str(randi() % 3 + 1)
		await get_tree().create_timer(SPIN_INTERVAL).timeout
	_action_label.text = ACTION_FACES.get(action, "🐉")
	if fire > 0:
		_fire_label.text = str(fire)
	if hoard > 0:
		_hoard_label.text = str(hoard)
	roll_finished.emit()
