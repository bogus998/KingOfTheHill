extends Node

enum TurnPhase { DICE_ROLL, RESOLUTION, BUY_CARDS, END_TURN }

signal phase_changed(new_phase: TurnPhase)
signal turn_started(player_index: int)
signal turn_ended(player_index: int)

var current_phase: TurnPhase = TurnPhase.DICE_ROLL
var current_player_index: int = 0
var roll_count: int = 0
var is_game_active: bool = false
var is_repeated_turn: bool = false
var _repeat_turn_pending: bool = false
var _repeat_turn_die_penalty: int = 0

func begin() -> void:
	is_game_active = true
	current_player_index = 0
	_start_turn()

func advance_phase() -> void:
	if not is_game_active:
		return
	match current_phase:
		TurnPhase.DICE_ROLL:
			_set_phase(TurnPhase.RESOLUTION)
		TurnPhase.RESOLUTION:
			_set_phase(TurnPhase.BUY_CARDS)
		TurnPhase.BUY_CARDS:
			turn_ended.emit(current_player_index)
			if _repeat_turn_pending:
				_repeat_turn_pending = false
				PlayerManager.players[current_player_index].pending_die_penalty = _repeat_turn_die_penalty
				_repeat_turn_die_penalty = 0
				is_repeated_turn = true
				_start_turn()
				is_repeated_turn = false
			else:
				_set_phase(TurnPhase.END_TURN)
		TurnPhase.END_TURN:
			pass  # caller must call next_player() explicitly

func next_player() -> void:
	if not is_game_active:
		return
	var start := current_player_index
	var size := PlayerManager.players.size()
	current_player_index = (current_player_index + 1) % size
	while PlayerManager.players[current_player_index].is_eliminated:
		current_player_index = (current_player_index + 1) % size
		if current_player_index == start:
			return  # all other players eliminated — win condition already fired
	_start_turn()

func request_repeat_turn(_player_index: int, die_penalty: int) -> void:
	_repeat_turn_pending = true
	_repeat_turn_die_penalty = die_penalty

func _start_turn() -> void:
	roll_count = 0
	# Award vault survival bonus before dice roll
	if PlayerManager.players[current_player_index].position == PlayerData.PlayerPosition.AT_VAULT:
		PlayerManager.add_gold(current_player_index, 2)
	turn_started.emit(current_player_index)
	_set_phase(TurnPhase.DICE_ROLL)

func _set_phase(phase: TurnPhase) -> void:
	current_phase = phase
	phase_changed.emit(phase)
