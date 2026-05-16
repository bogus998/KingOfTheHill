# Group 4 — Status Effect Cards: Implementation Plan

**Cards covered:** Plague Blade (`poison`), Weakening Curse (`shrink`), Stone Skin (`camouflage`), Dodge Roll (`gem_dodge`)

---

## 1. New State Fields in `PlayerData`

Add to `resources/player_data.gd`:

```gdscript
@export var poison_stacks: int = 0
@export var shrink_stacks: int = 0
@export var camouflage_active: bool = false
@export var gem_dodge_active: bool = false
```

All fields reset to defaults when `PlayerData.new()` is called at game setup.

---

## 2. Where Counters Are Applied and Decremented

### `poison_stacks`
- **Applied:** `_apply_effect("poison", player_index)` — increments stacks on all targets hit.
- **Ticks:** Top of `CardEffectHandler._on_turn_started`, before PERMANENT card loop. `apply_damage(player_index, poison_stacks)`, then `poison_stacks -= 1`. Guard with `if p.is_eliminated: return` after damage.

### `shrink_stacks`
- **Applied:** `_apply_effect("shrink", player_index)` — increments stacks on targets hit.
- **Consumed:** `DicePoolController._on_turn_started` — sets active die count to `max(1, base_dice - shrink_stacks)`.
- **Decremented:** `_on_turn_ended(player_index)` — `shrink_stacks -= 1` per turn until 0.

### `camouflage_active`
- **Applied:** `_apply_effect("camouflage", player_index)` (PERMANENT) — sets `camouflage_active = true` each turn.
- **Intercepted:** Inside `PlayerManager.apply_damage()` — per incoming damage point, roll a die; Heart result negates that point.
- **Cleared:** `_on_turn_ended(player_index)` — sets `camouflage_active = false`. Re-raised next turn by PERMANENT loop.

### `gem_dodge_active`
- **Applied:** `_apply_effect("gem_dodge", player_index)` (ONE_TIME) — spends 2 gems, sets flag true.
- **Intercepted:** `PlayerManager.apply_damage()` — if flag is true, skip all damage (do NOT clear; multiple hits per turn possible).
- **Cleared:** `_on_turn_ended(player_index)` — sets `gem_dodge_active = false`.

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

**`DicePoolController` change required:**
```gdscript
func set_active_die_count(count: int) -> void:
    for i in _dice.size():
        _dice[i].visible = (i < count)
```

Call from `DicePoolController._on_turn_started`:
```gdscript
var shrink := PlayerManager.players[player_index].shrink_stacks
var count := max(1, _dice.size() - shrink)
set_active_die_count(count)
```

**Decrement in `_on_turn_ended`:**
```gdscript
if PlayerManager.players[player_index].shrink_stacks > 0:
    PlayerManager.players[player_index].shrink_stacks -= 1
```

**Minimum:** Hard floor of 1 die via `max(1, ...)`.

**Bot concern:** Ensure `get_all_faces()` only returns visible dice faces to avoid stale values.

---

### `camouflage` — Stone Skin

**Card type:** PERMANENT.

**Activation:** Each turn, PERMANENT loop → `_apply_effect("camouflage", player_index)` → `camouflage_active = true`.

**Interception in `PlayerManager.apply_damage`:**
```gdscript
if p.camouflage_active:
    amount = _resolve_camouflage(amount)

func _resolve_camouflage(incoming: int) -> int:
    var remaining := incoming
    for _i in incoming:
        if randi() % 6 + 1 == DiceResolver.DieFace.HEART:
            remaining -= 1
    return max(0, remaining)
```

Use `DiceResolver.DieFace.HEART` constant, not a literal.

**Clear in `_on_turn_ended`:** `players[player_index].camouflage_active = false`

---

### `gem_dodge` — Dodge Roll

**Card type:** ONE_TIME.

**In `_apply_effect`:**
```gdscript
"gem_dodge":
    if not PlayerManager.players[player_index].gem_dodge_active:
        if PlayerManager.spend_gems(player_index, 2):
            PlayerManager.players[player_index].gem_dodge_active = true
```

**In `PlayerManager.apply_damage`:**
```gdscript
if p.gem_dodge_active:
    damage_applied.emit(attacker_index, player_index, 0)
    return
```

**Clear in `_on_turn_ended`:** `players[player_index].gem_dodge_active = false`

**Note:** Poison ticks at the victim's own turn start, by which time `gem_dodge_active` was already cleared. Poison damage is NOT blocked by Dodge Roll — correct behavior.

---

## 4. New Signals or Hooks Needed

`PlayerManager.apply_damage()` is already the single choke point for all HP reduction. No new signal is required to intercept damage for `camouflage` or `gem_dodge`.

**Optional additions for UI feedback:**

| Signal | Emitter | Use |
|---|---|---|
| `player_status_changed(player_index: int)` | `PlayerManager` | Update status icons on player panels |
| `damage_blocked(player_index: int, amount_blocked: int)` | `PlayerManager.apply_damage` | Drive "BLOCKED" visual feedback |

**DicePoolController:** `set_active_die_count(count: int)` is the only new method needed — not a signal.

---

## 5. Implementation Order

1. `PlayerData` fields — add all four; verify no runtime errors.
2. `gem_dodge` — simplest: no die rolls, no targeting. Test: play card with 2 gems, verify damage blocked, verify HP reduced next turn.
3. `poison` — add tick in `_on_turn_started`, add effect branch. Test: confirm tick fires, stacks decrement, death-by-poison works.
4. `camouflage` — add `_resolve_camouflage` to `PlayerManager`, guard in `apply_damage`, effect branch. Test: equip as PERMANENT, verify probabilistic reduction.
5. `shrink` — add `set_active_die_count` to `DicePoolController`, wire into `_on_turn_started`, add effect branch, decrement in `_on_turn_ended`. Test: verify die count reduces, minimum of 1 enforced, recovery after turns.
6. Status UI icons (post-MVP) — `player_status_changed` signal, panel updates.

---

## 6. Risks and Open Questions

| # | Question | Recommendation |
|---|---|---|
| R1 | Does poison stack across multiple applications? | Stack by default; add `MAX_POISON_STACKS = 5` cap if too lethal in playtesting |
| R2 | Shrink minimum die count | Hard `max(1, ...)` floor — non-negotiable |
| R3 | Camouflage Heart face value: is `DiceResolver.DieFace.HEART == 6`? | Confirm against `dice_resolver.gd`; use constant not literal |
| R4 | `gem_dodge` activated twice in same turn | Guard: skip if `gem_dodge_active` already true |
| R5 | Poison/shrink targeting — all opponents vs. single target | Default to "all opponents" (matches `_damage_others` pattern) |
| R6 | Bot AI awareness of status effects | Out of scope; document as known bot limitation |
| R7 | `randi()` in `PlayerManager` introduces non-determinism | Acceptable; extract seeded RNG later if test determinism needed |
| R8 | Shrink + `get_all_faces()` returning hidden-die values to bot | Fix `get_all_faces()` to skip non-visible dice |

---

## Files to Modify

| File | Change |
|---|---|
| `resources/player_data.gd` | 4 new fields |
| `autoloads/player_manager.gd` | `apply_damage` guard + `_resolve_camouflage` helper |
| `scripts/cards/card_effect_handler.gd` | 4 new effect branches, poison tick in `_on_turn_started`, cleanup in `_on_turn_ended` |
| `scripts/dice/dice_pool_controller.gd` | `set_active_die_count`, shrink enforcement in `_on_turn_started`, fix `get_all_faces` |
