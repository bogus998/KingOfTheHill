# Group 5 — Active Gold-Spend Abilities: Implementation Plan

**Cards covered:** Healing Flask (`rapid_healing`), Nimble Dodge (`nimble_dodge`), Slow Grinder (`slow_grinder`), Thrifty Trader (`gold_discount_1`), Healer's Forge (`paid_healing`)

---

## Codebase Context

- `CardEffectHandler` is a plain `RefCounted`, instantiated once in `main_game_controller.gd`.
- `TurnPhase` enum: `DICE_ROLL → RESOLUTION → BUY_CARDS → END_TURN`. Action bar's End Turn button only visible during `BUY_CARDS`.
- `ActionBarController` (`scripts/ui/action_bar_controller.gd`) is an `HBoxContainer` with a single `EndTurnButton`.
- `CardShop.purchase()` calls `PlayerManager.spend_gold(player_index, card.gold_cost)` directly — no discount hook exists.
- `ResolutionController.apply_non_claw()` applies hearts as self-heal only; no mechanism to redirect hearts.

---

## 1. UI Requirements

### Pattern A — "Spend gold anytime" button (`rapid_healing`, `nimble_dodge`, `slow_grinder`)

A new **ActiveAbilitiesPanel** (VBoxContainer scene) appears alongside existing UI during applicable phases. Each row shows: `[Card Name] [Cost: N gold] [USE button]`. USE button disabled when gold are insufficient or per-turn cap consumed.

**Where it fits:** Embed as a VBox above the End Turn button in `ActionBarController`. `main_game_controller` drives visibility via `phase_changed`.

- `rapid_healing`: available in RESOLUTION + BUY_CARDS.
- `nimble_dodge`: available in RESOLUTION + BUY_CARDS.
- `slow_grinder`: available in BUY_CARDS only.

Panel rebuilds at each turn start from active player's `cards_in_hand` filtered to gold-spend effect IDs.

### Pattern B — `gold_discount_1`

No button. Discount applied silently inside `CardShop.purchase()`. Cost labels update via `card_shop_controller._refresh_display()` to show discounted cost.

### Pattern C — `paid_healing`

Requires a **prompt dialog** shown to the target player (consent + payment). On a shared device this means an additional pass-device step mid-RESOLUTION. Most complex — defer to last.

---

## 2. New State / Flags in `PlayerData`

```gdscript
@export var nimble_dodge_used_this_turn: bool = false
@export var nimble_dodge_active: bool = false
```

- `nimble_dodge_used_this_turn` — prevents activating dodge a second time per turn.
- `nimble_dodge_active` — consumed by the next `apply_damage` call to negate 1 point.

Both flags reset at turn start inside `CardEffectHandler._on_turn_started()` for the active player, before passive effects fire.

No new flag for `rapid_healing` or `slow_grinder` (both are uncapped).

---

## 3. How `gold_discount_1` Hooks into the Card Shop

### Stateless discount computation (preferred)

Add helper to `CardShop` autoload:
```gdscript
func _gold_discount_for(player_index: int) -> int:
    var count := 0
    for c in PlayerManager.players[player_index].cards_in_hand:
        if c.effect_id == "gold_discount_1":
            count += 1
    return count
```

Modify `purchase()`:
```gdscript
var discount := _gold_discount_for(player_index)
var effective_cost := max(0, card.gold_cost - discount)
if not PlayerManager.spend_gold(player_index, effective_cost):
    return false
```

### Visual update in `CardShopController`

Modify `card_display_controller.refresh()` to accept optional `display_cost: int = -1` and use it when >= 0 for the cost label and affordability check.

---

## 4. Per-Effect Implementation Notes

### `rapid_healing` — Healing Flask (PERMANENT)

New method `CardEffectHandler.apply_active_ability(effect_id, player_index)`:
```gdscript
"rapid_healing":
    if PlayerManager.spend_gold(player_index, 2):
        PlayerManager.apply_heal(player_index, 1)
```

- Available in RESOLUTION + BUY_CARDS.
- No per-turn limit.
- Player at vault: `apply_heal` already returns early (no effect).
- Does NOT appear in `_apply_effect` passive loop.

### `nimble_dodge` — Nimble Dodge (PERMANENT)

In `apply_active_ability`:
```gdscript
"nimble_dodge":
    var p := PlayerManager.players[player_index]
    if not p.nimble_dodge_used_this_turn:
        if PlayerManager.spend_gold(player_index, 1):
            p.nimble_dodge_active = true
            p.nimble_dodge_used_this_turn = true
```

Damage intercept in `PlayerManager.apply_damage()`:
```gdscript
if p.nimble_dodge_active:
    p.nimble_dodge_active = false
    amount = max(0, amount - 1)
    if amount == 0:
        damage_applied.emit(attacker_index, player_index, 0)
        return
```

Reset both flags in `CardEffectHandler._on_turn_started`.

### `slow_grinder` — Slow Grinder (PERMANENT)

In `apply_active_ability`:
```gdscript
"slow_grinder":
    if PlayerManager.spend_gold(player_index, 3):
        PlayerManager.add_gems(player_index, 1)
```

- Available in BUY_CARDS only.
- No per-turn cap; USE button disabled when gold < 3.

### `gold_discount_1` — Thrifty Trader (PERMANENT)

- No USE button, no `_apply_effect` case.
- Stateless computation in `CardShop.purchase()` + visual update in `CardShopController`.
- Multiple copies stack (each reduces cost by 1, floor 0).

### `paid_healing` — Healer's Forge (PERMANENT)

- Trigger: after active player resolves Hearts in RESOLUTION, if they hold `paid_healing`, emit `paid_healing_offered(healer_index, hearts_rolled)` if hearts > 0.
- Flow:
  1. `ResolutionController.apply_non_claw()` emits signal after self-heal.
  2. `main_game_controller` catches it, shows targeting dialog.
  3. Healer selects target + amount.
  4. Pass device to target for consent.
  5. On consent: `spend_gold(target, amount * 2)`, `apply_heal(target, amount)`.
  6. Phase continues normally.
- Defer until after all other Group 5 effects are implemented.

---

## 5. New Signals or Hooks Needed

| Signal / Method | Owner | Purpose |
|---|---|---|
| `ability_used(effect_id, player_index)` | `ActiveAbilitiesPanelController` | Routes USE button presses to `CardEffectHandler` |
| `paid_healing_offered(healer_index, hearts)` | `ResolutionController` | Triggers paid-heal targeting dialog |
| `apply_active_ability(effect_id, player_index)` | `CardEffectHandler` (new public method) | Executes gold-spend effect |

---

## 6. Implementation Order

1. `PlayerData` flags — add `nimble_dodge_used_this_turn` and `nimble_dodge_active`.
2. `gold_discount_1` — stateless hook in `CardShop.purchase()` + visual update. Self-contained.
3. `slow_grinder` — implement `apply_active_ability` stub + `ActiveAbilitiesPanelController` skeleton.
4. `rapid_healing` — extend panel and `apply_active_ability`. Validate RESOLUTION visibility.
5. `nimble_dodge` — add damage intercept to `PlayerManager.apply_damage()`. Extend panel.
6. `paid_healing` — targeting dialog, consent flow, bot question.

---

## 7. Risks and Open Questions

| # | Question | Recommendation |
|---|---|---|
| Q1 | ActiveAbilitiesPanel layout space (third column vs. above End Turn) | Decide before Step 3; prefer embedding above End Turn button |
| Q2 | `rapid_healing` "anytime" — allow during DICE_ROLL? | Restrict to RESOLUTION + BUY_CARDS to avoid disrupting dice UX |
| Q3 | `nimble_dodge` blocking passive damage from other players' turns | Correct behavior — flag is consumed by next `apply_damage` regardless of whose turn |
| Q4 | Bot support for active abilities | Defer; add simple heuristics (heal if HP < 5, convert gold if gold > 6) as follow-up |
| Q5 | `paid_healing` on shared device requires mid-RESOLUTION device pass | Extend `PassDeviceScreen` to support mid-phase; design first |
| Q6 | `gold_discount_1` and shop refresh cost | Discount does NOT apply to 2-gold refresh cost |
| Q7 | Multiple Thrifty Trader copies: stack or cap? | Stack by default; clamp with `min(count, 1)` if undesired |

---

## Tests

**Test file:** `tests/unit/test_m5_group5_gold.gd` (create when implementing this group)

Active gold-spend effects are triggered by `CardEffectHandler.apply_active_ability` — test through that method, not through UI signals. UI wiring (`ActionAbilitiesPanel`, `PassDeviceScreen`) must be verified manually.

| Effect | Scenarios to cover |
|---|---|
| `gold_discount_1` | `CardShop.purchase` succeeds with 1 fewer gold; card is still not buyable when gold < (cost - discount); two copies stack the discount |
| `rapid_healing` | `apply_active_ability` deducts the gold cost and applies heal; no heal when gold insufficient |
| `nimble_dodge` | `nimble_dodge_active` flag set by `apply_active_ability`; next `apply_damage` call blocked; flag cleared after first blocked hit; second hit in same turn lands |
| `slow_grinder` | `apply_active_ability` converts gold to gems at the correct rate; no conversion when gold = 0 |
| `paid_healing` | Heal applied when `resolution_controller` emits `paid_healing_offered` and player accepts; gold deducted; no effect if declined |

---

## Files to Modify

| File | Change |
|---|---|
| `resources/player_data.gd` | `nimble_dodge_used_this_turn`, `nimble_dodge_active` flags |
| `autoloads/player_manager.gd` | Nimble dodge intercept in `apply_damage` |
| `autoloads/card_shop.gd` | `_gold_discount_for` helper, discount in `purchase()` |
| `scripts/cards/card_effect_handler.gd` | `apply_active_ability` method |
| `scripts/cards/card_shop_controller.gd` | Display discounted cost |
| `scripts/ui/action_bar_controller.gd` | Add ActiveAbilitiesPanel |
| `scripts/game/main_game_controller.gd` | Wire `ability_used` signal, `paid_healing_offered` |
| `scripts/game/resolution_controller.gd` | Emit `paid_healing_offered` when applicable |
