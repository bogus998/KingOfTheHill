extends HBoxContainer

signal end_roll_requested
signal end_turn_requested

@onready var _end_roll_btn: Button = $EndRollButton
@onready var _end_turn_btn: Button = $EndTurnButton

func _ready() -> void:
	TurnManager.phase_changed.connect(_on_phase_changed)
	TurnManager.turn_started.connect(_on_turn_started)
	_end_roll_btn.pressed.connect(func(): end_roll_requested.emit())
	_end_turn_btn.pressed.connect(func(): end_turn_requested.emit())
	_on_phase_changed(TurnManager.current_phase)

func set_end_roll_enabled(value: bool) -> void:
	_end_roll_btn.disabled = not value

func _on_turn_started(_player_index: int) -> void:
	_end_roll_btn.disabled = true

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	_end_roll_btn.visible = (phase == TurnManager.TurnPhase.DICE_ROLL)
	_end_turn_btn.visible = (phase == TurnManager.TurnPhase.BUY_CARDS)
