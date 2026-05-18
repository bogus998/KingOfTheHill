# Card Effect & UI Audit

**Date:** 2026-05-18  
**Scope:** All 79 cards — effect logic correctness + player-facing UI wiring

---

## Dead Infrastructure (Root Cause for Multiple Cards)

Three mechanisms are fully implemented but **never wired to any UI or consumer**:

1. **`DicePoolController.enter_die_selection_mode(callback)`** — die-selection flow exists, never called from anywhere in the real game
2. **`CardEffectHandler.use_smoke_bomb_charge()`** — handler fully implemented, zero callers
3. **`player.wildcard_pending`** and **`can_set_die_before_roll`** flags — written by effects, never read by any script

---

## Critical — Effect Never Works At All

### Wildcard (card_051) — ACTIONABLE
- **Should:** Change one of your dice to any face.
- **Logic:** `WildcardDieEffect.apply_immediate` only sets `player.wildcard_pending = true`. That flag is never read anywhere (grep-confirmed across all scripts, scenes, autoloads, resources).
- **UI:** ActiveAbilitiesPanel shows a row (ACTIONABLE). Button fires → `apply_active_ability(WILDCARD_DIE)` → no-op. No die-picker, no face-picker. `enter_die_selection_mode` would be the natural mechanism but is never invoked.
- **Result:** Button exists, silently discards the card with zero effect.

### Die Picker (card_036) — PERMANENT
- **Should:** Once per turn, change any of your dice to ONE before rolling.
- **Logic:** `SetDieToOneEffect.on_turn_started` sets `can_set_die_before_roll = true`. That flag is never read (only set/reset — grep-confirmed).
- **UI:** None. PERMANENT card, not ACTIONABLE, not in ActiveAbilitiesPanel whitelist. No pre-roll die-selection UI exists anywhere.
- **Result:** Card does nothing. Player has no way to trigger it.

### Die Jacker (card_054) — PERMANENT
- **Should:** Once per turn, reroll one die of each other dwarf.
- **Logic:** No-op base `CardEffect`. `DIE_JACKER` enum value exists but has no effect subclass and no handler in `apply_active_ability`.
- **UI:** None. Not in ActiveAbilitiesPanel. No targeting UI.
- **Result:** Completely unimplemented (both logic and UI).

### Healer's Forge (card_034) — PERMANENT
- **Should:** Use Heart results to heal other dwarfs; they pay you 2 gold per HP restored.
- **Logic:** No-op base `CardEffect`. No handler for `PAID_HEALING` anywhere.
- **UI:** None.
- **Result:** Completely unimplemented.

### Flexible Tactics (card_062) — PERMANENT
- **Should:** Spend 2 gold to change one of your dice to any result.
- **Logic:** No-op base `CardEffect`. Not in `apply_active_ability` match, not in `_is_gold_active_effect()`.
- **UI:** None. Not ACTIONABLE, not in panel whitelist.
- **Result:** Completely unimplemented.

### Focus Crystal (card_064) — PERMANENT
- **Should:** Spend 1 gold to gain 1 extra reroll.
- **Logic:** No-op base `CardEffect`. Same as Flexible Tactics.
- **UI:** None. Not ACTIONABLE, not in panel whitelist.
- **Result:** Completely unimplemented.

### Smoke Bomb — PERMANENT
- **Should:** Spend a charge for one extra reroll during dice phase.
- **Logic:** `CardEffectHandler.use_smoke_bomb_charge()` is fully implemented (decrements charge, grants `extra_rerolls_available += 1`, discards when empty). Charges are seeded on purchase.
- **UI:** None. Not ACTIONABLE, not in panel whitelist. No "Spend Charge" button anywhere.
- **Result:** Handler is dead code. Card is unusable by a human player.

### Dodge Roll (card_068) — ONE_TIME
- **Should:** Spend 2 gold to negate all damage you would take this turn.
- **Logic:** ONE_TIME card — `DodgeRollEffect.apply_immediate` runs at purchase, sets `gold_dodge_active`, spends 2 gold. Flag is cleared at `on_turn_ended` of the **same turn**. You take no incoming damage during your own buy phase, so the protection window is always empty.
- **UI:** None needed (consumed at purchase), but the timing makes the card functionally useless.
- **Result:** Effectively does nothing useful.

### Trickster's Bargain (card_079) — PERMANENT
- **Should:** When you flee the Vault, steal a PERMANENT card from the claiming dwarf.
- **Logic:** No-op base `CardEffect`. No hook in `handle_flee` or `_on_flee`.
- **UI:** No card-pick dialog wired to flee flow.
- **Result:** Completely unimplemented (both logic and UI).

---

## Partial — Broken in Common Cases

### Stone Skin (card_016) — `CAMOUFLAGE`
- **Should:** When you take damage, roll a die — on Heart, negate that damage.
- **Bug:** `camouflage_active` is set in `on_turn_started` and cleared in `on_turn_ended` — only during the **owner's own turn**. Attacks arrive on opponents' turns (the common case), so damage is never mitigated.
- **Severity:** Partial — works only in a window where incoming damage rarely occurs.

### Shockwave Axe (card_046) — `NOVA_ATTACK`
- **Should:** Claw results deal damage to ALL other dwarfs.
- **Bug:** Nova fires only in one of three claw branches (OUTSIDE attacking an occupied vault). In-vault claw attacks and OUTSIDE → empty vault entry don't trigger nova.
- **Severity:** Partial.

### Weakening Curse (card_058) — `SHRINK`
- **Should:** When you deal damage, give the target a shrink counter reducing their die count.
- **Bug:** `WeakeningCurseEffect.apply_immediate` immediately AoEs one shrink stack onto every other non-eliminated player on purchase. It is ONE_TIME — it cannot be a persistent on-hit effect. Description and behavior are completely different mechanics.
- **Severity:** Partial (wrong mechanic vs. description).

### Copycat / Mimic (card_043) — `MIMIC`
- **Should:** Copy the effect of any PERMANENT card held by any dwarf.
- **Bug:** `complete_mimic` only calls `chosen_card.effect.on_turn_started(player_index)`. Cards whose effect lives in `on_turn_ended`, `on_acquired`, dice passives, or stat modifiers (e.g. Iron Hide, Heavy Strike) are silently not copied.
- **UI:** Card-pick dialog works correctly.
- **Severity:** Partial — only turn-start passives are copied.

### Sharp Eye (card_049) — `OPPORTUNIST`
- **Should:** Whenever a new card is revealed, you may buy it before others.
- **Bug:** The interrupt handler explicitly skips bots (`if p.is_bot: continue`). Bots holding Sharp Eye never get the interrupt.
- **UI:** Works for human players — interrupt popup appears correctly.
- **Severity:** Partial (bots excluded).

### Recycle (card_042) — `RECYCLE_CARDS`
- **Should:** At end of turn, discard any PERMANENT cards to recover their gold cost.
- **Bug:** `needs_recycle()` is only checked for non-bot players in `_on_end_turn`. Bots can't use this card.
- **UI:** End-of-turn picker dialog works correctly for human players.
- **Severity:** Partial (bots excluded).

### Nimble Dodge (card_076) — `NIMBLE_DODGE`
- **Should:** Spend 1 gold to negate 1 incoming damage.
- **Bug:** Button is available in RESOLUTION/BUY_CARDS phases. Player must pre-activate; there is no reactive prompt when damage is about to land. Functional but timing UX is unintuitive.
- **UI:** Gold-spend button in ActiveAbilitiesPanel works correctly.
- **Severity:** Minor (UX gap, not a logic bug).

---

## Minor — Works But with Wrong Semantics

### Second Wind (card_038) / Shield Bearer (card_073)
- Both describe restoring to "10 health" but actually restore to `max_health`. If Iron Constitution was played, that's 12 HP — description is misleading.

### War Band (card_070)
- On purchase with 0 cards in hand, the card counts 0 cards and does nothing for its gold cost. Edge case.

### Intimidating Warcry (card_067) — `INTIMIDATING_ROAR`
- Forces flee even if the attack dealt 0 damage (no "damage > 0" check). Minor.

### Plague Blade (card_053) — `POISON`
- Poison damage ticks with `attacker_index = -1`, so it never triggers on-hit bonuses from other cards (Thorned Armor, Life Drain, etc.). Minor interaction gap; poison itself works correctly.

---

## Cards with Working Logic and UI

| Card | Notes |
|---|---|
| Healing Flask (055) | Gold-spend button in panel, correct phase gating |
| Nimble Dodge (076) | Gold-spend button works; pre-activation UX gap |
| Slow Grinder (075) | Gold-spend button, BUY_CARDS phase only |
| Recycle (042) | End-of-turn picker dialog; bots excluded |
| Copycat / Mimic (043) | Picker dialog works; only copies turn-start passives |
| Sharp Eye / Opportunist (049) | Interrupt popup; bots excluded |
| Forge Master / Peek Deck (041) | Shop peek button correctly gated |
| Merchant's Touch / Buy From Others (050) | Shop UI correctly gated |
| Plague Blade (053) | Poison applies and ticks; minor edge interactions |
| War Drums (078) | Penalty applied correctly next turn |
| Tunnel Fighter (015) | Both halves (bonus damage + flee damage) work |

---

## Structural Issue: ActiveAbilitiesPanel Hardcoded Whitelist

`ActiveAbilitiesPanel` only shows rows for cards that are either `ACTIONABLE` (type 2) **or** whose `effect_id` is in a hardcoded list of exactly 3 effects: `RAPID_HEALING`, `NIMBLE_DODGE`, `SLOW_GRINDER`. Costs and names are also hardcoded in the panel rather than read from card data.

Any new gold-spend or charge-spend card (Smoke Bomb, Flexible Tactics, Focus Crystal) is invisible to the player unless manually added to this whitelist.

---

## Priority Fix Order

1. Wire `enter_die_selection_mode` — unlocks Wildcard (button already exists), Die Picker, Die Jacker
2. Add Smoke Bomb to ActiveAbilitiesPanel whitelist and wire `use_smoke_bomb_charge()` to the button
3. Hook Trickster's Bargain into the flee flow with a card-pick dialog
4. Fix Stone Skin — move `camouflage_active` to a persistent passive checked on any incoming damage
5. Fix Shockwave Axe nova — apply to all three claw branches
6. Decide fate of Flexible Tactics / Focus Crystal / Dodge Roll (make ACTIONABLE or implement gold-spend panel entries)
7. Fix Weakening Curse description or change mechanic to match description
8. Fix Copycat to dispatch the correct hook per copied card's effect type
