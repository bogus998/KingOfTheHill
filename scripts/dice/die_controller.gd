extends PanelContainer

enum DieState { ACTIVE, HELD }

var face: DiceResolver.DieFace = DiceResolver.DieFace.ONE
var state: DieState = DieState.ACTIVE

@onready var _face_label: Label = $FaceLabel

signal face_changed(new_face: DiceResolver.DieFace)
signal hold_changed(is_held: bool)

func _ready() -> void:
	_face_label.text = _face_to_text(face)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle_hold()
		accept_event()

func roll() -> void:
	if state == DieState.HELD:
		return
	var faces := DiceResolver.DieFace.values()
	face = faces[randi() % faces.size()]
	_face_label.text = _face_to_text(face)
	emit_signal("face_changed", face)

func toggle_hold() -> void:
	state = DieState.HELD if state == DieState.ACTIVE else DieState.ACTIVE
	modulate = Color(0.5, 0.7, 1.0) if state == DieState.HELD else Color.WHITE
	emit_signal("hold_changed", state == DieState.HELD)

func reset_hold() -> void:
	if state == DieState.HELD:
		state = DieState.ACTIVE
		modulate = Color.WHITE
		emit_signal("hold_changed", false)

func set_face(f: DiceResolver.DieFace) -> void:
	face = f
	if _face_label != null:
		_face_label.text = _face_to_text(face)

func _face_to_text(f: DiceResolver.DieFace) -> String:
	match f:
		DiceResolver.DieFace.ONE:   return "1"
		DiceResolver.DieFace.TWO:   return "2"
		DiceResolver.DieFace.THREE: return "3"
		DiceResolver.DieFace.GEM:   return "⚡"
		DiceResolver.DieFace.CLAW:  return "🐾"
		DiceResolver.DieFace.HEART: return "❤️"
	return "?"
