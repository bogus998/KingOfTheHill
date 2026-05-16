class_name ActionBarController
extends HBoxContainer

signal end_turn_requested

@onready var _end_turn_btn: Button = $EndTurnButton

func _ready() -> void:
	TurnManager.phase_changed.connect(_on_phase_changed)
	_end_turn_btn.pressed.connect(func(): end_turn_requested.emit())
	_on_phase_changed(TurnManager.current_phase)

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	_end_turn_btn.visible = (phase == TurnManager.TurnPhase.BUY_CARDS)
