extends Panel

signal flee_pressed
signal stay_pressed

@onready var _message: Label = $VBoxContainer/MessageLabel
@onready var _flee_btn: Button = $VBoxContainer/Buttons/FleeButton
@onready var _stay_btn: Button = $VBoxContainer/Buttons/StayButton

func _ready() -> void:
	_flee_btn.pressed.connect(func(): flee_pressed.emit())
	_stay_btn.pressed.connect(func(): stay_pressed.emit())

func show_dialog(attacker_name: String, defender_name: String) -> void:
	_message.text = "%s attacks! %s: Flee or Stay?" % [attacker_name, defender_name]
	visible = true

func hide_dialog() -> void:
	visible = false
