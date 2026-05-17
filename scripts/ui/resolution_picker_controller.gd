class_name ResolutionPickerController
extends Panel

signal apply_requested

@onready var _summary: Label = $VBoxContainer/SummaryLabel
@onready var _apply_btn: Button = $VBoxContainer/ApplyButton

func _ready() -> void:
	_apply_btn.pressed.connect(func(): apply_requested.emit())
	visible = false

func show_result(result: Dictionary) -> void:
	var parts: Array[String] = []
	if result["gems"] > 0:   parts.append("%d Gems" % result["gems"])
	if result["gold"] > 0:   parts.append("%d Gold" % result["gold"])
	if result["claws"] > 0:  parts.append("%d Claws" % result["claws"])
	if result["hearts"] > 0: parts.append("%d Hearts" % result["hearts"])
	_summary.text = "Roll: " + (", ".join(parts) if parts.size() > 0 else "Nothing")
	visible = true

func hide_picker() -> void:
	visible = false
