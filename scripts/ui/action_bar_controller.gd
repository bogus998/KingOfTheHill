extends HBoxContainer

signal end_roll_requested
signal end_turn_requested

@onready var _end_roll_btn: Button = $EndRollButton
@onready var _end_turn_btn: Button = $EndTurnButton

func _ready() -> void:
	TurnManager.phase_changed.connect(_on_phase_changed)
	_end_roll_btn.pressed.connect(func(): emit_signal("end_roll_requested"))
	_end_turn_btn.pressed.connect(func(): emit_signal("end_turn_requested"))
	_on_phase_changed(TurnManager.current_phase)

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	_end_roll_btn.visible = (phase == TurnManager.TurnPhase.DICE_ROLL)
	_end_turn_btn.visible = (phase == TurnManager.TurnPhase.BUY_CARDS)
