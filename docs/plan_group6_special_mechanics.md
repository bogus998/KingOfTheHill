# Group 6 — Special/Complex Card Mechanics: Implementation Plan

**Cards covered:** Second Wind (`respawn`), Shield Bearer (`shield_bearer`), Bloodlust (`extra_turn`), Gold Battery (`gold_battery`), Recycle (`recycle_cards`), Copycat (`mimic`), Forge Master (`peek_deck`), Merchant's Touch (`buy_from_others`), Sharp Eye (`opportunist`)

---

## 1. Game-Loop Changes Needed

### 1a. Elimination Interception (`respawn` / `shield_bearer`)

Currently `PlayerManager._eliminate()` sets `is_eliminated = true` unconditionally.

**Required change:** At the top of `_eliminate`, call `_check_revival(player_index) -> bool`. If it returns true, death is cancelled and the function returns early.

```gdscript
func _eliminate(player_index: int) -> void:
    if _check_revival(player_index):
        return
    players[player_index].is_eliminated = true
    player_eliminated.emit(player_index)

func _check_revival(player_index: int) -> bool:
    # Check shield_bearer first (keeps cards)
    for card in players[player_index].cards_in_hand:
        if card.effect_id == "shield_bearer":
            remove_card_from_hand(player_index, card)
            players[player_index].gems = 0
            gem_changed.emit(player_index, 0)
            players[player_index].health = players[player_index].max_health
            player_healed.emit(player_index, players[player_index].health)
            player_respawned.emit(player_index)
            return true
    # Then respawn (clears all cards)
    for card in players[player_index].cards_in_hand.duplicate():
        if card.effect_id == "respawn":
            players[player_index].cards_in_hand.clear()
            card_hand_changed.emit(player_index)
            players[player_index].gems = 0
            gem_changed.emit(player_index, 0)
            players[player_index].health = players[player_index].max_health
            player_healed.emit(player_index, players[player_index].health)
            player_respawned.emit(player_index)
            return true
    return false
```

**Data fix required:** `card_038_second_wind.tres` has `card_type = 0` (ONE_TIME). Must be changed to `1` (PERMANENT). Without this fix, Second Wind fires on purchase (noop) and is immediately discarded.

### 1b. Extra Turn (`extra_turn`)

Add to `turn_manager.gd`:
```gdscript
var pending_extra_turn: bool = false
```

In `next_player()`, at the top:
```gdscript
if pending_extra_turn:
    pending_extra_turn = false
    _start_turn(current_player_index)
    return
```

`extra_turn` is ONE_TIME; `apply_immediate` sets `TurnManager.pending_extra_turn = true` during BUY_CARDS phase. `next_player()` fires at END_TURN.

### 1c. Gold Battery Auto-Discard

`gold_battery` is PERMANENT; `_on_turn_started` fires `_apply_effect("gold_battery", idx)` each turn. The handler decrements a per-card charge counter and removes the card at zero. Requires per-instance mutable state on `CardData` (see Section 2a).

### 1d. Opportunist — Shop Interrupt

`CardShop._replenish()` emits a new signal `new_card_revealed(card: CardData, slot_index: int)` for each newly added card. `main_game_controller` pauses the active turn and shows a buy-or-pass prompt to any alive non-active player holding `opportunist`.

---

## 2. New State / Flags Needed

### 2a. `CardData.charges` field

Add to `resources/card_data.gd`:
```gdscript
@export var charges: int = 0
```

Used only by `gold_battery`. Set to 6 in `CardEffectHandler._on_card_purchased` when `card.effect_id == "gold_battery"`. Decremented each turn. Auto-discards at zero.

**Risk:** `ResourceLoader` may cache `.tres` files and two players could share the same `CardData` object, sharing `charges`. Fix: call `card.duplicate()` inside `PlayerManager.add_card_to_hand()`.

### 2b. `TurnManager.pending_extra_turn`

```gdscript
var pending_extra_turn: bool = false
```

### 2c. `PlayerManager.signal player_respawned(player_index: int)`

New signal emitted by `_check_revival` for UI feedback (flash HP bar, show message).

---

## 3. UI Requirements

### `mimic` (Copycat) — card-picker dialog

New scene: `scenes/ui/card_picker_dialog.tscn`
- Scrollable list of all PERMANENT cards held by alive opponents (name, description, owner name).
- Emits `card_selected(card: CardData)` or `cancelled` (no-op).
- Exclude: other `mimic` cards (infinite recursion), `gold_battery` (no charge tracking for mimicked copy).
- Bot: picks card with highest `gold_cost`.

### `recycle_cards` (Recycle) — discard-for-refund picker

Reuse or extend `card_picker_dialog.tscn`. Filter to active player's own PERMANENT cards, excluding Recycle itself. Multi-select. Shows gold refund per card.

Appears during `_apply_turn_end_effect("recycle_cards")` — requires async pattern (see Section 5).

### `peek_deck` (Forge Master) — deck-peek overlay

Add "Peek Deck" button to shop UI, visible during BUY_CARDS when active player holds `peek_deck`. On press: show peeked card with cost + "Buy" / "Pass" buttons.

### `buy_from_others` (Merchant's Touch) — buy-from-player picker

"Buy from Dwarfs" button in shop UI, visible when active player holds `buy_from_others`. Opens list of PERMANENT cards from other alive players. On selection: `spend_gold(buyer, card.gold_cost)` + `remove_card_from_hand(owner)` + `add_card_to_hand(buyer)`.

### `opportunist` (Sharp Eye) — interrupt prompt

Minimal modal (based on `escape_dialog.tscn`): shows newly revealed card's name, description, and cost. "Buy" and "Pass" buttons. Appears mid-turn when a non-active player holds Sharp Eye and a card is added to shop.

---

## 4. Per-Effect Implementation Notes

### `respawn` — Second Wind

- Fix `card_038_second_wind.tres`: change `card_type = 0` to `card_type = 1`.
- Handled in `PlayerManager._check_revival()` (see Section 1a).
- Clears ALL cards and gems, restores to `max_health`.

### `shield_bearer` — Shield Bearer

- Handled in `_check_revival()`, checked BEFORE `respawn` (keeps cards, only removes shield_bearer card).
- Sets gems = 0, health = max_health.

### `extra_turn` — Bloodlust (ONE_TIME)

In `_apply_effect`:
```gdscript
"extra_turn":
    TurnManager.pending_extra_turn = true
```

### `gold_battery` — Gold Battery (PERMANENT)

In `_on_card_purchased`:
```gdscript
if card.effect_id == "gold_battery":
    card.charges = 6
```

In `_apply_effect`:
```gdscript
"gold_battery":
    for card in PlayerManager.players[player_index].cards_in_hand:
        if card.effect_id == "gold_battery" and card.charges > 0:
            PlayerManager.add_gold(player_index, 2)
            card.charges -= 1
            if card.charges <= 0:
                PlayerManager.remove_card_from_hand(player_index, card)
            break
```

### `recycle_cards` — Recycle (PERMANENT)

In `_apply_turn_end_effect`:
```gdscript
"recycle_cards":
    var refundable := []
    for card in PlayerManager.players[player_index].cards_in_hand:
        if card.card_type == CardData.CardType.PERMANENT and card.effect_id != "recycle_cards":
            refundable.append(card)
    if not refundable.is_empty():
        recycle_ui_needed.emit(player_index)
        # Await continuation via signal bridge (see Section 5)
```

Continuation: `complete_recycle(player_index, chosen_cards: Array[CardData])` — for each: `remove_card_from_hand` + `add_gold(card.gold_cost)`.

### `mimic` — Copycat (PERMANENT)

In `_apply_effect` (fires each turn start):
```gdscript
"mimic":
    # Collect eligible PERMANENT cards from alive opponents
    # Emit mimic_ui_needed(player_index) if any eligible cards found
    # Continuation: complete_mimic(player_index, chosen_card)
    #   → _apply_effect(chosen_card.effect_id, player_index)
```

Exclude `mimic` and `gold_battery` from eligible cards.

### `peek_deck` — Forge Master (PERMANENT)

New `CardShop` methods:
- `peek_top() -> CardData`: returns `_deck.back()` or null. No side effects.
- `purchase_top(player_index: int) -> bool`: pops `_deck.back()`, applies purchase flow.

Detected in `main_game_controller._on_phase_changed(BUY_CARDS)` — show "Peek Deck" button.

### `buy_from_others` — Merchant's Touch (PERMANENT)

Detected in `main_game_controller._on_phase_changed(BUY_CARDS)` — show "Buy from Dwarfs" button.

Transfer logic: `spend_gold(buyer, card.gold_cost)` → `remove_card_from_hand(owner, card)` → `add_card_to_hand(buyer, card)`.

### `opportunist` — Sharp Eye (PERMANENT)

`CardShop._replenish()` emits `new_card_revealed(card, slot_index)` for each new card. `main_game_controller` checks if any alive non-active player holds `opportunist`. If yes, shows interrupt prompt. After resolution (buy or pass), resumes active turn.

For multiple Sharp Eye holders: serve in player-index order relative to active player.

---

## 5. Async Pattern for Interactive Turn Effects

`_apply_effect` and `_apply_turn_end_effect` are synchronous. For `recycle_cards` and `mimic`, UI responses are needed mid-execution.

**Recommended: Signal bridge.** The handler emits `recycle_ui_needed` / `mimic_ui_needed`. `main_game_controller` opens the dialog, collects result, and calls a continuation method on `CardEffectHandler` (`complete_recycle`, `complete_mimic`). The turn phase does not advance until the controller calls the continuation.

This avoids making `_on_turn_started` / `_on_turn_ended` async.

---

## 6. Implementation Order (Least to Most Disruptive)

### Phase 1 — Pure logic, no UI

1. **`gold_battery`** — Add `charges` to `CardData`. Set to 6 on purchase. Decrement/discard. Also add `card.duplicate()` to `add_card_to_hand`.
2. **`extra_turn`** — Add `pending_extra_turn` to `TurnManager`. One-line change in `next_player()`.
3. **`respawn` + `shield_bearer`** — Fix `card_038_second_wind.tres` card_type. Add `_check_revival` in `_eliminate`. Emit `player_respawned` signal.

### Phase 2 — Turn-start/end UI dialogs

4. Async pattern infrastructure — build `card_picker_dialog.tscn`, wire continuation callbacks.
5. **`recycle_cards`** — Hook into `_apply_turn_end_effect`. Wire dialog.
6. **`mimic`** — Hook into `_apply_effect`. Wire dialog. Test exclusion rules.

### Phase 3 — Buy-phase capability UI

7. **`peek_deck`** — Add `peek_top()` / `purchase_top()` to `CardShop`. Add Peek Deck button.
8. **`buy_from_others`** — Add Buy from Dwarfs button. Implement transfer logic.

### Phase 4 — Cross-turn interrupt (most disruptive)

9. **`opportunist`** — Add `new_card_revealed` to `CardShop._replenish()`. Implement interrupt flow.

---

## 7. Risks and Open Questions

| # | Risk / Question | Recommendation |
|---|---|---|
| R1 | Shared `CardData` instances across players | Call `card.duplicate()` in `PlayerManager.add_card_to_hand()` |
| R2 | `second_wind` card_type data bug (= 0, should be 1) | Fix `card_038_second_wind.tres` first — do NOT test without this fix |
| R3 | Async architecture: signal bridge vs. full async | Decide before Phase 2; document in code comments |
| R4 | `mimic` + `gold_battery` interaction | Exclude `gold_battery` from mimic targets explicitly |
| R5 | Multiple revival cards in one hand | Check `shield_bearer` first (keeps cards); consume only one per death |
| R6 | Opportunist with bot as Sharp Eye holder | Defer bot+opportunist after human+opportunist is proven |
| Q1 | Merchant's Touch buying a Gold Battery with remaining charges | Charges transfer naturally with the card object — confirm this is intended |
| Q2 | Sharp Eye when active player causes the replenish | No interrupt needed — active player is already in BUY_CARDS and sees new card normally |
| Q3 | Forge Master: peek and buy visible cards independently? | Yes, both are independent BUY_CARDS phase actions |

---

## Tests

**Test file:** `tests/unit/test_m5_group6_special.gd` (create when implementing this group)

Group 6 has the most UI-coupled effects. Focus unit tests on pure logic paths that don't require dialog input. Dialog-driven flows (`mimic`, `recycle_cards`, `buy_from_others`, `opportunist`) must be tested manually on-device.

| Effect | Scenarios to cover | UI-only |
|---|---|---|
| `respawn` | Player HP reaches 0 → `player_respawned` emitted at 1 HP; card consumed; second elimination (no `respawn` in hand) is permanent | No |
| `shield_bearer` | Ally reaches 0 HP → shield holder takes the killing blow instead; shield card consumed; holder's own death does not trigger shield | No |
| `extra_turn` | `TurnManager.pending_extra_turn` set to true after `apply_immediate`; card removed from hand | No |
| `gold_battery` | Gold granted while card is in hand decrement charge counter; card auto-removed from hand at 0 charges | No |
| `recycle_cards` | Gold awarded per card discarded; hand size decreases | Yes — picker dialog |
| `mimic` | Effect of chosen card applied to caster; `mimic` itself excluded from picker options | Yes — picker dialog |
| `peek_deck` | Top N cards of deck inspected without purchasing; deck order unchanged | Yes — peek overlay |
| `buy_from_others` | Purchase succeeds using target player's visible card; card removed from target's shop slot | Yes — buy picker |
| `opportunist` | Interrupt fires when shop refreshes; caster can buy new card before active player | Yes — interrupt prompt |

---

## Files to Modify

| File | Change |
|---|---|
| `resources/card_data.gd` | Add `charges: int = 0` field |
| `data/cards/card_038_second_wind.tres` | Fix `card_type = 1` |
| `autoloads/player_manager.gd` | `_check_revival`, `player_respawned` signal, `add_card_to_hand` duplicate |
| `autoloads/turn_manager.gd` | `pending_extra_turn` flag in `next_player()` |
| `autoloads/card_shop.gd` | `peek_top`, `purchase_top`, `new_card_revealed` signal |
| `scripts/cards/card_effect_handler.gd` | All new effect handlers, continuation callbacks |
| `scripts/game/main_game_controller.gd` | Dialog wiring, phase-change hooks, interrupt flow |
| Scene: `scenes/ui/card_picker_dialog.tscn` | New scene for mimic/recycle UI |
