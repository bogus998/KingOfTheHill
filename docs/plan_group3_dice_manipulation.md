# Group 3 — Dice Manipulation: Implementation Plan

**Cards covered:** Extra Axe (`extra_die`), Quick Hands (`bonus_reroll_1`), Shadow Runner (`free_reroll_threes`), Die Picker (`set_die_to_one`), Flexible Tactics (`gold_die_change`), Focus Crystal (`gold_extra_reroll`), Wildcard (`wildcard_die`), Smoke Bomb (`smoke_bomb`), Perfect Roll (`all_faces_bonus`), Combo Master (`combo_master`), Treasure Seeker (`triple_one_gems_bonus_2`), Time Stopper (`triple_one_extra_turn`), Toxic Blade (`triple_two_damage_2`), War Drums (`war_drums`)

---

## 1. Systems That Need to Change

### `scripts/dice/dice_pool_controller.gd` — central change point

- `const MAX_ROLLS := 3` — replace with `func _get_max_rolls() -> int` that reads `PlayerData.extra_rerolls_available + 3`.
- `_dice` is populated from scene children at `_ready()` — die count is structurally fixed. Add hidden extra-die nodes in the scene (e.g. 2 extras, `visible = false`). In `_on_turn_started`, show/hide based on `PlayerData.die_count_modifier`.
- Add `enter_die_selection_mode(callback: Callable)` — makes each die tappable, fires callback with chosen index.
- After each roll, if active player has `free_reroll_threes`, un-hold all THREE-face dice without consuming roll count.
- Add signal `extra_roll_available(remaining: int)` for UI.

### `autoloads/turn_manager.gd`

Add:
```gdscript
var _repeat_turn_pending: bool = false
var _repeat_turn_die_penalty: int = 0

func request_repeat_turn(player_index: int, die_penalty: int) -> void:
    _repeat_turn_pending = true
    _repeat_turn_die_penalty = die_penalty
```

In `advance_phase()` at `BUY_CARDS → END_TURN`: if `_repeat_turn_pending`, call `_start_turn()` for the same player (passing penalty via `PlayerData.pending_die_penalty`), then clear flags.

### `resources/player_data.gd`

New transient fields (all reset at turn start unless noted):

| Field | Type | Reset | Purpose |
|---|---|---|---|
| `die_count_modifier` | `int` | turn start | Net extra/fewer dice (stacks) |
| `extra_rerolls_available` | `int` | turn start | Gold/charge-funded bonus rolls |
| `has_free_reroll_after_max` | `bool` | after first use or turn end | Quick Hands |
| `free_reroll_threes` | `bool` | turn end (set each turn start) | Shadow Runner always-active |
| `can_set_die_before_roll` | `bool` | after first use or turn end | Die Picker |
| `pending_die_penalty` | `int` | consumed at next turn start | Time Stopper repeated-turn penalty |
| `repeat_turn_used` | `bool` | turn start | Prevents Time Stopper infinite loop |
| `war_drums_triggered` | `bool` | turn end | Did dice score >= 4 gems |

Card-level charge counters (`smoke_bomb_charges`) go in `CardEffectHandler._card_charges: Dictionary` keyed by `CardData` object reference, NOT in `PlayerData`.

### `scripts/cards/card_effect_handler.gd`

- Add `var _card_charges: Dictionary = {}` for Smoke Bomb.
- Add `func on_roll_finalized(player_index: int, final_faces: Array) -> void` — called from `MainGameController._on_end_roll()` before advancing phase. All post-roll pattern checks live here.
- Extend `_on_turn_started` to set modifier flags from PERMANENT cards.
- Extend `_on_turn_ended` to clear per-turn flags and apply War Drums debuffs.

### `scripts/game/main_game_controller.gd`

- In `_on_end_roll()`, before `TurnManager.advance_phase()`, call `_card_effect_handler.on_roll_finalized(TurnManager.current_player_index, _dice_pool.get_all_faces())`.

### `scripts/dice/dice_resolver.gd`

Add three static helpers:
```gdscript
static func has_all_six_faces(faces: Array) -> bool
static func has_combo_one_two_three(faces: Array) -> bool
static func count_face(faces: Array, face: DieFace) -> int
```

---

## 2. Per-Effect Implementation Notes

### `extra_die` — Extra Axe (PERMANENT)
- `_on_turn_started`: `players[player_index].die_count_modifier += 1`
- `DicePoolController._on_turn_started`: show/hide pre-placed hidden die nodes based on modifier.
- Multiple copies stack. Cap at scene's physical die count.

### `bonus_reroll_1` — Quick Hands (PERMANENT)
- `_on_turn_started`: set `has_free_reroll_after_max = true`
- `DicePoolController`: after `_roll_count == MAX_ROLLS` and flag is true, keep Roll button enabled labelled "Free Reroll". Next press clears flag and rolls without incrementing `_roll_count`.

### `free_reroll_threes` — Shadow Runner (PERMANENT)
- `_on_turn_started`: set `free_reroll_threes = true`
- `DicePoolController`: after each roll, un-hold any THREE-face dice. Don't disable Roll button while un-held THREE-face dice remain, even after roll 3.
- Edge case: player cannot hold a THREE to score triple-THREE gems.

### `set_die_to_one` — Die Picker (PERMANENT)
- `_on_turn_started`: set `can_set_die_before_roll = true`. Show "Set to ONE" button only while `_roll_count == 0`.
- Player taps a die → `die.set_face(DieFace.ONE)`. Clear flag after one use.

### `gold_die_change` — Flexible Tactics (PERMANENT)
- "Set Die (2 gold)" button visible when player has card AND `gold >= 2`.
- Button press → die-selection mode → face-picker popup → `set_face(chosen)` + `spend_gold(player_index, 2)`.
- Can be used multiple times per turn (gold are the limiter).

### `gold_extra_reroll` — Focus Crystal (PERMANENT)
- "Extra Roll (1 gold)" button visible when `_roll_count >= effective_max_rolls` AND `gold >= 1`.
- `spend_gold(player_index, 1)` → `extra_rerolls_available += 1` → re-enable Roll button.

### `wildcard_die` — Wildcard (ONE_TIME)
- `apply_immediate` sets `wildcard_pending = true`. During next DICE_ROLL turn start, face-picker flow fires → `set_face(chosen)` → clear flag. Card already discarded by ONE_TIME path.
- Effect fires next turn's DICE_ROLL phase (card bought in BUY_CARDS). Document in card description.

### `smoke_bomb` — Smoke Bomb (PERMANENT, charge-based)
- `_on_card_purchased`: `_card_charges[card] = 3`
- During DICE_ROLL: "Smoke Bomb" button visible when charges > 0 AND `_roll_count >= effective_max_rolls`. Press: `_card_charges[card] -= 1`, `extra_rerolls_available += 1`.
- When `_card_charges[card] == 0`: `remove_card_from_hand` and append to `spent_one_time_cards`.

### `all_faces_bonus` — Perfect Roll (PERMANENT)
- `on_roll_finalized()`: check `DiceResolver.has_all_six_faces(final_faces)` → `add_gems(player_index, 9)`.
- With 7+ dice, only need all six distinct faces present at least once.

### `combo_master` — Combo Master (PERMANENT)
- `on_roll_finalized()`: check `DiceResolver.has_combo_one_two_three(final_faces)` → `add_gems(player_index, 2)`.
- Fires independently from triple-ONE gems scoring; both are additive.

### `triple_one_gems_bonus_2` — Treasure Seeker (PERMANENT)
- `on_roll_finalized()`: `DiceResolver.count_face(final_faces, DieFace.ONE) >= 3` → `add_gems(player_index, 2)`.
- Standard resolver already awards 1 gems for triple-ONE; this adds 2 more (total: 3).

### `triple_one_extra_turn` — Time Stopper (PERMANENT)
- `on_roll_finalized()`: count ONEs >= 3 → `TurnManager.request_repeat_turn(player_index, 1)`.
- `TurnManager.advance_phase()` at `BUY_CARDS → END_TURN`: if `_repeat_turn_pending`, call `_start_turn()` for same player with `pending_die_penalty = 1`, clear flag.
- `DicePoolController._on_turn_started`: subtract `pending_die_penalty` from visible dice, then clear it.
- Edge case: set a `_repeat_turn_used` guard to prevent infinite loop if player rolls triple-ONE again.

### `triple_two_damage_2` — Toxic Blade (PERMANENT)
- `on_roll_finalized()`: `DiceResolver.count_face(final_faces, DieFace.TWO) >= 3` → `_damage_others(player_index, 2)`.

### `war_drums` — War Drums (PERMANENT)
- `on_roll_finalized()`: if dice gems result >= 4, set `war_drums_triggered = true`.
- `_on_turn_ended()`: if `war_drums_triggered`, apply `die_count_modifier -= 1` to all other living players. Clear flag.
- Cap opponents' `die_count_modifier` floor so players always roll at least 1 die.
- Only dice gems (`_last_roll_result["gems"]`) counts, not card-granted gems.

---

## 3. Implementation Order

1. `PlayerData` modifier fields
2. `DicePoolController`: variable die count (hidden extra nodes, show/hide from modifier)
3. `DicePoolController`: variable roll count (`_get_max_rolls()`)
4. `CardEffectHandler.on_roll_finalized` hook + `DiceResolver` helpers → unlocks all pattern-check effects
5. `TurnManager.request_repeat_turn` → unlocks `triple_one_extra_turn`
6. Die mutation UI (`enter_die_selection_mode` + face picker) → unlocks `set_die_to_one`, `gold_die_change`, `wildcard_die`
7. Shadow Runner passive (THREE-unhold pass in `roll_active_dice`)
8. Quick Hands free reroll (conditional re-enable after roll 3)

---

## 4. Risks and Open Questions

| # | Risk | Recommendation |
|---|---|---|
| R1 | Variable die count requires scene editing (pre-place hidden nodes) | Pre-place 2 extra `DieController` nodes in `DiceContainer`; cap at 7 |
| R2 | Signal ordering: `DicePoolController._on_turn_started` fires before `CardEffectHandler` sets `die_count_modifier` | Use `_update_die_visibility.call_deferred()` in `DicePoolController._on_turn_started` |
| R3 | Hidden dice in `_dice` array are rolled and included in `get_all_faces()` | Filter by `die.visible` in `roll_active_dice()` and `get_all_faces()` |
| R4 | Repeated turn double-fires income/damage passives (`gold_per_turn_1`, `passive_damage_1_per_turn`, etc.) | Add `is_repeated_turn: bool` to `TurnManager`; skip income/damage passives in `CardEffectHandler._on_turn_started` when set |
| R5 | Bot roll loop hardcoded to `range(3)` — won't use bonus rolls | Replace with a loop checking `_dice_pool.roll_count < _dice_pool.get_max_rolls()` |
| R6 | `TurnManager._start_turn()` must reset everything correctly on repeat | Verify PERMANENT card passives fire correctly on repeated turn |
| R7 | War Drums threshold: dice gems vs all gems sources | Default to dice-only gems (`DiceResolver.resolve(final_faces)["gems"]`) |
| R8 | Wildcard timing (ONE_TIME bought in BUY_CARDS, effect deferred to next turn) | Document in card description |
| R9 | Time Stopper recursion (triple-ONE again on repeated turn) | Add `repeat_turn_used: bool` guard to `PlayerData`; reset at turn start |
| R10 | Combo Master vs. triple scoring interaction | Both fire independently and are additive — intentional |
| R11 | Bot support for interactive effects | Add stubs to `BotBrain`: Die Picker/Wildcard → pick ONE; Flexible Tactics → match most frequent face |

---

## Tests

**Test file:** `tests/unit/test_m5_group3_dice.gd`

All Group 3 effects are already covered. When adding new effects to this group, append tests to that file following the existing pattern (`before_each`/`after_each` shared, one test per scenario).

| Effect | Covered scenarios |
|---|---|
| `extra_die` | `die_count_modifier` incremented; stacks with two copies |
| `bonus_reroll_1` | `has_free_reroll_after_max` flag set |
| `free_reroll_threes` | `free_reroll_threes` flag set |
| `set_die_to_one` | `can_set_die_before_roll` flag set |
| modifier reset | All flags cleared at turn start |
| `wildcard_die` | `wildcard_pending` set; card removed (ONE_TIME) |
| `smoke_bomb` | Extra reroll on use; card removed when charges depleted |
| `all_faces_bonus` | 9 gems on all six faces; 0 gems when a face is missing |
| `combo_master` | 2 gems on 1-2-3 combo; 0 gems without all three |
| `triple_one_gems_bonus_2` | 2 gems on triple ONE; 0 gems with only two ONEs |
| `triple_one_extra_turn` | `repeat_turn_pending` set; blocked when guard already used |
| `repeat_turn_used` | Persists through repeated turn; resets on normal turn start |
| `triple_two_damage_2` | 2 damage to others on triple TWO; no damage without triple |
| `war_drums` | Triggered on 4+ gems roll; debuffs others on `turn_ended`; no debuff when not triggered |
| repeated-turn income | Passives skipped; die modifiers still apply |

---

## Files to Modify

| File | Change |
|---|---|
| `resources/player_data.gd` | Add transient modifier fields |
| `scripts/dice/dice_pool_controller.gd` | Variable die count, roll count, die mutation, Shadow Runner, Quick Hands |
| `scripts/dice/dice_resolver.gd` | Add 3 static helper functions |
| `autoloads/turn_manager.gd` | Add `request_repeat_turn()` |
| `scripts/cards/card_effect_handler.gd` | Add `_card_charges`, `on_roll_finalized`, modifier-flag setting, War Drums debuff |
| `scripts/game/main_game_controller.gd` | Wire `on_roll_finalized` |
| `scripts/ai/bot_brain.gd` | Add stubs for interactive effects |
| DiceContainer scene | Add 2 extra hidden `DieController` nodes |
