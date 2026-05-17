class_name ActionBarController
extends VBoxContainer

signal end_turn_requested
signal ability_used(effect_id: CardEffectId.Id, player_index: int)

@onready var _end_turn_btn: Button = $EndTurnButton
@onready var _abilities_panel: ActiveAbilitiesPanelController = $ActiveAbilitiesPanel

func _ready() -> void:
	TurnManager.phase_changed.connect(_on_phase_changed)
	_end_turn_btn.pressed.connect(func(): end_turn_requested.emit())
	_abilities_panel.ability_used.connect(ability_used.emit)
	_on_phase_changed(TurnManager.current_phase)

func _on_phase_changed(phase: TurnManager.TurnPhase) -> void:
	_end_turn_btn.visible = (phase == TurnManager.TurnPhase.BUY_CARDS)
