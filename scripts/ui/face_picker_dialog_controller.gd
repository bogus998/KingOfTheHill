class_name FacePickerDialogController
extends PanelContainer

signal face_chosen(face: DiceResolver.DieFace)

const _FACES: Array[DiceResolver.DieFace] = [
	DiceResolver.DieFace.ONE, DiceResolver.DieFace.TWO, DiceResolver.DieFace.THREE,
	DiceResolver.DieFace.GOLD, DiceResolver.DieFace.CLAW, DiceResolver.DieFace.HEART,
]

func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	var vbox := VBoxContainer.new()
	add_child(vbox)

	var label := Label.new()
	label.text = "Pick a face:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	for face: DiceResolver.DieFace in _FACES:
		var btn := Button.new()
		btn.text = _face_label(face)
		btn.custom_minimum_size = Vector2(64, 64)
		var f: DiceResolver.DieFace = face
		btn.pressed.connect(func():
			visible = false
			face_chosen.emit(f)
		)
		hbox.add_child(btn)

func show_picker() -> void:
	visible = true

func _face_label(f: DiceResolver.DieFace) -> String:
	match f:
		DiceResolver.DieFace.ONE:   return "1"
		DiceResolver.DieFace.TWO:   return "2"
		DiceResolver.DieFace.THREE: return "3"
		DiceResolver.DieFace.GOLD:  return "⚡"
		DiceResolver.DieFace.CLAW:  return "🐾"
		DiceResolver.DieFace.HEART: return "❤️"
	return "?"
