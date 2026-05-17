# Group 4 — Status Effect Cards: Implementation Plan

**Cards covered:** Plague Blade (`poison`), Weakening Curse (`shrink`), Stone Skin (`camouflage`), Dodge Roll (`gold_dodge`)

---

## 1. New State Fields in `PlayerData`

Add to `resources/player_data.gd`:

```gdscript
var poison_stacks: int = 0
var shrink_stacks: int = 0
var camouflage_active: bool = false
var gold_dodge_active: bool = false
```

Plain `var`, not `@export` — these are runtime state, not inspector-editable config. Matches the pattern of `die_count_modifier`, `extra_rerolls_available`, and other per-turn fields already in `PlayerData`.

---

## 2. Where Counters Are Applied and Decremented

### `poison_stacks`
- **Applied:** `_apply_effect("poison", player_index)` — increments stacks on all targets hit.
- **Ticks:** Top of `CardEffectHandler._on_turn_started`, before PERMANENT card loop. `apply_damage(player_index, poison_stacks)`, then `poison_stacks -= 1`. Guard with `if p.is_eliminated: return` after damage.

### `shrink_stacks`
- **Applied:** `_apply_effect("shrink", player_index)` — increments stacks on targets hit.
- **Consumed:** `CardEffectHandler._on_turn_started` — after the PERMANENT loop, applies `p.die_count_modifier -= p.shrink_stacks`. `DicePoolController._update_die_visibility` (already called deferred) picks this up via the existing `clampi(BASE_DIE_COUNT + die_count_modifier - penalty, 1, _dice.size())` formula. No new `DicePoolController` method needed.
- **Decremented:** `_on_turn_ended(player_index)` — unconditional status cleanup outside the card loop: `shrink_stacks -= 1` per turn until 0.

### `camouflage_active`
- **Applied:** `_apply_effect("camouflage", player_index)` (PERMANENT) — sets `camouflage_active = true` each turn.
- **Intercepted:** Inside `PlayerManager.apply_damage()` — per incoming damage point, roll a die; Heart result negates that point.
- **Cleared:** `_on_turn_ended(player_index)` — sets `camouflage_active = false`. Re-raised next turn by PERMANENT loop.

### `gold_dodge_active`
- **Applied:** `_apply_effect("gold_dodge", player_index)` (ONE_TIME) — spends 2 gold, sets flag true.
- **Intercepted:** `PlayerManager.apply_damage()` — if flag is true, skip all damage (do NOT clear; multiple hits per turn possible).
- **Cleared:** `_on_turn_ended(player_index)` — sets `gold_dodge_active = false`.

---

## 3. Per-Effect Implementation Notes

### `poison` — Plague Blade

**Card type:** ONE_TIME.

**Targeting:** Apply to all opponents damaged by the current attack (same as `_damage_others` pattern). In `_apply_effect("poison")`, iterate all non-self, non-eliminated players and increment their `poison_stacks`.

**Turn-start tick (in `_on_turn_started`, before PERMANENT loop):**
```gdscript
var p := PlayerManager.players[player_index]
if p.poison_stacks > 0:
    PlayerManager.apply_damage(player_index, p.poison_stacks)
    p.poison_stacks -= 1
    if p.is_eliminated:
        return
```

**Stacking:** Each application adds 1 stack. A player with 3 stacks takes 3 damage turn 1, 2 on turn 2, 1 on turn 3.

---

### `shrink` — Weakening Curse

**Card type:** ONE_TIME.

**Targeting:** Same as poison — apply to all opponents hit.

**`CardEffectHandler._on_turn_started` change (after PERMANENT loop):**
```gdscript
if p.shrink_stacks > 0:
    p.die_count_modifier -= p.shrink_stacks
```

`_update_die_visibility` in `DicePoolController` is already called deferred at turn start. It computes:
```gdscript
var target := clampi(BASE_DIE_COUNT + p.die_count_modifier - penalty, 1, _dice.size())
```
The `clampi(..., 1, ...)` enforces the minimum-1-die floor. No new method needed in `DicePoolController`.

**Decrement in `_on_turn_ended` (unconditional, outside the card loop):**
```gdscript
if p.shrink_stacks > 0:
    p.shrink_stacks -= 1
```

---

### `camouflage` — Stone Skin

**Card type:** PERMANENT.

**Activation:** Each turn, PERMANENT loop → `_apply_effect("camouflage", player_index)` → `camouflage_active = true`.

**Interception in `PlayerManager.apply_damage` (after gold_dodge check, before damage_reduction):**
```gdscript
if p.gold_dodge_active:
    damage_applied.emit(attacker_index, player_index, 0)
    return
if p.camouflage_active:
    amount = _resolve_camouflage(amount)
var actual: int = max(0, amount - p.damage_reduction)
```

```gdscript
func _resolve_camouflage(incoming: int) -> int:
    var remaining := incoming
    for _i in incoming:          # valid GDScript 4: iterates `incoming` times
        if randi() % 6 + 1 == DiceResolver.DieFace.HEART:
            remaining -= 1
    return max(0, remaining)
```

`HEART == 6`, so each incoming damage point has a 1/6 chance to be negated. Use the constant, not a literal. `for _i in n` (int) is valid GDScript 4.

**Clear in `_on_turn_ended` (unconditional, outside card loop):** `p.camouflage_active = false`

---

### `gold_dodge` — Dodge Roll

**Card type:** ONE_TIME.

**In `_apply_effect`:**
```gdscript
"gold_dodge":
    if not PlayerManager.players[player_index].gold_dodge_active:
        if PlayerManager.spend_gold(player_index, 2):
            PlayerManager.players[player_index].gold_dodge_active = true
```

**In `PlayerManager.apply_damage`:**
```gdscript
if p.gold_dodge_active:
    damage_applied.emit(attacker_index, player_index, 0)
    return
```

**Clear in `_on_turn_ended` (unconditional, outside card loop):** `p.gold_dodge_active = false`

**Note:** Dodge blocks ALL incoming damage for the full turn — the flag is NOT cleared on the first hit. It persists until `_on_turn_ended`. Poison ticks at the victim's own turn start, by which time `gold_dodge_active` was already cleared, so poison damage is NOT blocked by Dodge Roll — correct behavior.

---

## 4. `_on_turn_ended` Status Cleanup

Status cleanup is unconditional and lives **outside** the existing PERMANENT card loop, at the end of `_on_turn_ended`:

```gdscript
func _on_turn_ended(player_index: int) -> void:
    if player_index >= PlayerManager.players.size():
        return
    # ... existing card loop for PERMANENT turn-end effects ...
    var p := PlayerManager.players[player_index]
    if p.shrink_stacks > 0:
        p.shrink_stacks -= 1
    p.camouflage_active = false
    p.gold_dodge_active = false
```

`camouflage_active` and `gold_dodge_active` are always cleared regardless of value. `shrink_stacks` only decrements when positive.

---

## 5. New Signals or Hooks Needed (Optional)

`PlayerManager.apply_damage()` is already the single choke point for all HP reduction. No new signal is required to intercept damage for `camouflage` or `gold_dodge`.

**Optional additions for UI feedback:**

| Signal | Emitter | Use |
|---|---|---|
| `player_status_changed(player_index: int)` | `PlayerManager` | Update status icons on player panels |
| `damage_blocked(player_index: int, amount_blocked: int)` | `PlayerManager.apply_damage` | Drive "BLOCKED" visual feedback |

**DicePoolController:** No new methods needed — shrink integrates via `die_count_modifier` and the existing `_update_die_visibility`.

---

## 6. Implementation Order

1. `PlayerData` fields — add all four; verify no runtime errors.
2. `gold_dodge` — simplest: no die rolls, no targeting. Test: play card with 2 gold, verify damage blocked, verify HP reduced next turn.
3. `poison` — add tick in `_on_turn_started`, add effect branch. Test: confirm tick fires, stacks decrement, death-by-poison works.
4. `camouflage` — add `_resolve_camouflage` to `PlayerManager`, guard in `apply_damage`, effect branch. Test: equip as PERMANENT, verify probabilistic reduction.
5. `shrink` — add effect branch, apply `die_count_modifier -= shrink_stacks` after PERMANENT loop in `_on_turn_started`, decrement in `_on_turn_ended`. Test: verify die count reduces, minimum of 1 enforced, recovery after turns.
6. Status UI icons (post-MVP) — `player_status_changed` signal, panel updates.

---

## 7. Risks and Open Questions

| # | Question | Recommendation |
|---|---|---|
| R1 | Does poison stack across multiple applications? | Stack by default; add `MAX_POISON_STACKS = 5` cap if too lethal in playtesting |
| R2 | Shrink minimum die count | Hard `max(1, ...)` floor — non-negotiable |
| R3 | Camouflage Heart face value | Confirmed: `DiceResolver.DieFace.HEART == 6`. Always use constant, not literal. |
| R4 | `gold_dodge` activated twice in same turn | Guard: skip if `gold_dodge_active` already true |
| R5 | Poison/shrink targeting — all opponents vs. single target | Default to "all opponents" (matches `_damage_others` pattern) |
| R6 | Bot AI awareness of status effects | Out of scope; document as known bot limitation |
| R7 | `randi()` in `PlayerManager` introduces non-determinism | Acceptable; extract seeded RNG later if test determinism needed |

---

## Tests

**Test file:** `tests/unit/test_m5_group4_status.gd` (create when implementing this group)

Use the same `before_each`/`after_each`/`_make_card` pattern as the other group test files. Camouflage involves `randi()` — either seed the RNG before the test or test only that the signal fires, not the exact HP value.

| Effect | Scenarios to cover |
|---|---|
| `poison` | Tick fires each `turn_started`; HP decreases by stack count; stacks decrement by 1 per tick; stacks reach 0 and stop; player can be eliminated by poison tick |
| `gold_dodge` | `gold_dodge_active` set on card play (costs 2 gold); ALL `apply_damage` calls return early while flag is true (not just the first); multiple hits in same turn all blocked; flag is `false` after `_on_turn_ended` fires; poison tick next turn is NOT blocked |
| `shrink` | `die_count_modifier` reduced by shrink stacks after PERMANENT loop in `_on_turn_started`; `_update_die_visibility` enforces minimum 1 die via `clampi`; stacks decrement each `turn_ended`; `die_count_modifier` returns to normal once stacks reach 0 |
| `camouflage` | Verify `_resolve_camouflage` is invoked on incoming damage; at minimum assert `damage_applied` signal fires (exact HP depends on RNG — do not assert specific value unless RNG is seeded) |

---

## Files to Modify

| File | Change |
|---|---|
| `resources/player_data.gd` | 4 new fields |
| `autoloads/player_manager.gd` | `apply_damage` guard + `_resolve_camouflage` helper |
| `scripts/cards/card_effect_handler.gd` | 4 new effect branches, poison tick in `_on_turn_started`, cleanup in `_on_turn_ended` |
| `scripts/dice/dice_pool_controller.gd` | No changes needed — `_update_die_visibility` and `get_all_faces` already handle shrink correctly via `die_count_modifier` |
