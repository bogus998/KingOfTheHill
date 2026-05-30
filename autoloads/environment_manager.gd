extends Node
## Owns the single active Environment Card and its lifecycle.
##
## The dragon queues a card on awakening (`draw_and_queue`); it activates at the
## next round start and is dismissed at that round's end — active for exactly one
## whole round, only ever one at a time. Reactive game events are forwarded to the
## active card here; pull-style query getters delegate to it (consulted by other
## managers in M-Dragon-6).

signal card_activated(card: EnvironmentEffect)
signal card_dismissed(card: EnvironmentEffect)

var active_card: EnvironmentEffect = null
var pending_card: EnvironmentEffect = null

var _deck: Array[EnvironmentEffect] = []

func _ready() -> void:
	TurnManager.round_started.connect(_on_round_started)
	TurnManager.round_ended.connect(_on_round_ended)
	PlayerManager.damage_applied.connect(_on_damage_applied)
	PlayerManager.gold_gained.connect(_on_gold_gained)
	PlayerManager.players_setup.connect(_reset_state)

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _reset_state() -> void:
	active_card = null
	pending_card = null

## Draw a random environment (with replacement) to activate next round.
func draw_and_queue() -> void:
	if _deck.is_empty():
		_deck = EnvironmentDeck.load_all()
	if _deck.is_empty():
		return
	pending_card = _deck[randi() % _deck.size()].duplicate()

func _on_round_started(_round_number: int) -> void:
	if pending_card != null:
		active_card = pending_card
		pending_card = null
		card_activated.emit(active_card)
		active_card.on_round_started()

func _on_round_ended(_round_number: int) -> void:
	if active_card != null:
		active_card.on_round_ended()
		var dismissed := active_card
		active_card = null
		card_dismissed.emit(dismissed)

# ── Reactive event forwarding ─────────────────────────────────────────────────

func _on_damage_applied(attacker_index: int, target_index: int, amount: int) -> void:
	if active_card != null:
		active_card.on_damage_applied(attacker_index, target_index, amount)

func _on_gold_gained(player_index: int, amount: int) -> void:
	if active_card != null:
		active_card.on_gold_gained(player_index, amount)

## Called by the dice flow when a player finalizes their roll (wired in M-Dragon-6).
func notify_roll_finalized(player_index: int, roll_count: int, final_faces: Array) -> void:
	if active_card != null:
		active_card.on_roll_finalized(player_index, roll_count, final_faces)

# ── Query delegation (neutral when no card is active) ─────────────────────────

func roll_limit() -> int:
	return active_card.roll_limit() if active_card != null else -1

func dice_count_delta() -> int:
	return active_card.dice_count_delta() if active_card != null else 0

func shop_cost_delta() -> int:
	return active_card.shop_cost_delta() if active_card != null else 0

func vault_entry_surcharge() -> int:
	return active_card.vault_entry_surcharge() if active_card != null else 0

func purchasing_allowed() -> bool:
	return active_card.purchasing_allowed() if active_card != null else true

func cards_active() -> bool:
	return active_card.cards_active() if active_card != null else true

func damage_cap() -> int:
	return active_card.damage_cap() if active_card != null else -1

func grants_free_reroll() -> bool:
	return active_card.grants_free_reroll() if active_card != null else false

func vault_holder_gold_bonus() -> int:
	return active_card.vault_holder_gold_bonus() if active_card != null else 0

func blocks_vault_holder_gold() -> bool:
	return active_card.blocks_vault_holder_gold() if active_card != null else false
