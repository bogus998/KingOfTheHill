extends Node
## Shared dragon threat. Player actions accumulate Rage through a generic
## BuildupTracker; when Rage trips its (scaling) threshold the dragon awakens.
##
## This manager is the game-side consumer of the project-agnostic buildup layer
## ([[threshold_meter]] / [[buildup_tracker]]): it detects which gameplay events
## feed rage (and any conditions the generic layer cannot know — vault streaks,
## per-turn damage), reports them, and runs the awakening when the threshold is
## tripped. Awakening is latched the moment rage trips (a visible warning) but
## only resolves at the end of the round (`TurnManager.round_ended`).

const RAGE_RULES_PATH := "res://data/dragon/rage_rules.tres"

## Threshold to trip the Nth awakening, indexed by player count then by
## awakening index (0 = 1st, clamped to last row for 4th+).
const ESCALATION := {
	2: [5, 4, 3, 2],
	3: [7, 5, 4, 3],
	4: [9, 6, 5, 4],
}

signal rage_changed(value: int)
signal awakening_pending()
signal awakening_started()
signal dragon_die_rolled(die: int, face: int)
signal awakening_resolved(summary: Dictionary)

var awakening_count: int = 0
var rage_threshold: int = 0

var _tracker: BuildupTracker = null
var _dice: DragonDice = DragonDice.new()
var _player_count: int = 2
var _awakening_pending: bool = false
var _vault_streak: Dictionary = {}   # player_index -> consecutive turns held
var _buys_this_turn: int = 0
var _buy_reported: bool = false

func _ready() -> void:
	PlayerManager.players_setup.connect(_on_players_setup)
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.turn_ended.connect(_on_turn_ended)
	TurnManager.round_ended.connect(_on_round_ended)
	CardShop.card_purchased.connect(_on_card_purchased)
	CardShop.shop_refreshed.connect(_on_shop_refreshed)

# ── Public query API ──────────────────────────────────────────────────────────

var rage: int:
	get: return _tracker.value if _tracker != null else 0

var is_awakening_pending: bool:
	get: return _awakening_pending

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _on_players_setup() -> void:
	_player_count = PlayerManager.players.size()
	awakening_count = 0
	_awakening_pending = false
	_vault_streak.clear()
	_buys_this_turn = 0
	_buy_reported = false
	_dice = DragonDice.new()
	rage_threshold = _threshold_for(0)
	var config := load(RAGE_RULES_PATH) as BuildupConfig
	_tracker = BuildupTracker.new(config, rage_threshold)
	_tracker.value_changed.connect(func(v: int) -> void: rage_changed.emit(v))
	_tracker.threshold_reached.connect(_on_threshold_reached)
	rage_changed.emit(0)

func _threshold_for(awakening_index: int) -> int:
	var row: Array = ESCALATION.get(clampi(_player_count, 2, 4), ESCALATION[2])
	return row[mini(awakening_index, row.size() - 1)]

# ── Rage detection glue (game-side conditions) ────────────────────────────────

func _on_turn_started(player_index: int) -> void:
	_buys_this_turn = 0
	_buy_reported = false
	if _tracker == null:
		return
	if PlayerManager.players[player_index].position == PlayerData.PlayerPosition.AT_VAULT:
		var streak: int = _vault_streak.get(player_index, 0) + 1
		_vault_streak[player_index] = streak
		if streak == 2:
			_tracker.report(&"vault_held_2nd")
		elif streak >= 3:
			_tracker.report(&"vault_held_3rd_plus")
	else:
		_vault_streak[player_index] = 0

func _on_turn_ended(player_index: int) -> void:
	if _tracker == null:
		return
	if PlayerManager.players[player_index].damage_dealt_this_turn >= 3:
		_tracker.report(&"damage_3plus_in_turn")

func _on_card_purchased(_player_index: int, _card: CardData) -> void:
	if _tracker == null:
		return
	_buys_this_turn += 1
	if _buys_this_turn >= 2 and not _buy_reported:
		_buy_reported = true
		_tracker.report(&"bought_2plus_cards")

func _on_shop_refreshed() -> void:
	if _tracker == null:
		return
	_tracker.report(&"shop_refreshed")

# ── Awakening ─────────────────────────────────────────────────────────────────

func _on_threshold_reached(_value: int) -> void:
	if not _awakening_pending:
		_awakening_pending = true
		awakening_pending.emit()

func _on_round_ended(_round_number: int) -> void:
	if _awakening_pending:
		_resolve_awakening()

func _resolve_awakening() -> void:
	_awakening_pending = false
	awakening_started.emit()
	var summary: Dictionary = {}
	# Evict the vault holder — they drop OUTSIDE (and so earn no vault gems next turn).
	var occupant := PlayerManager.get_vault_occupant()
	summary["evicted"] = occupant
	if occupant != -1:
		PlayerManager.set_position(occupant, PlayerData.PlayerPosition.OUTSIDE)
	# Roll the dragon dice and apply the outcome.
	var action := _dice.roll_action()
	summary["action"] = action
	dragon_die_rolled.emit(0, action)
	var fire := 0
	var hoard := 0
	var draw_environment := false
	match action:
		DragonDice.Action.FIRE:
			fire = _dice.roll_fire()
		DragonDice.Action.HOARD:
			hoard = _dice.roll_hoard()
		DragonDice.Action.ENVIRONMENT:
			draw_environment = true
		DragonDice.Action.WRATH:
			fire = _dice.roll_fire()
			hoard = _dice.roll_hoard()
			draw_environment = true
		DragonDice.Action.SLUMBER:
			pass
	if fire > 0:
		dragon_die_rolled.emit(1, fire)
		_apply_fire(fire)
	if hoard > 0:
		dragon_die_rolled.emit(2, hoard)
		_apply_hoard(hoard)
	summary["fire"] = fire
	summary["hoard"] = hoard
	if draw_environment:
		summary["draw_environment"] = true
		EnvironmentManager.draw_and_queue()
	# Reset and escalate for the next awakening.
	_tracker.reset()
	awakening_count += 1
	rage_threshold = _threshold_for(awakening_count)
	_tracker.set_threshold(rage_threshold)
	awakening_resolved.emit(summary)

func _apply_fire(amount: int) -> void:
	for i in PlayerManager.players.size():
		if not PlayerManager.players[i].is_eliminated:
			PlayerManager.apply_damage(i, amount, -1)

func _apply_hoard(amount: int) -> void:
	for i in PlayerManager.players.size():
		if not PlayerManager.players[i].is_eliminated:
			var have: int = PlayerManager.players[i].gold
			PlayerManager.spend_gold(i, mini(amount, have))

## Restore rage/awakening state from a saved snapshot. The rage value lives behind
## the private tracker, so this is the only way to rehydrate it from outside.
func restore_state(rage_value: int, threshold: int, awakenings: int, pending: bool) -> void:
	rage_threshold = threshold
	awakening_count = awakenings
	_awakening_pending = pending
	if _tracker != null:
		_tracker.set_threshold(threshold)
		_tracker.set_value(rage_value)
