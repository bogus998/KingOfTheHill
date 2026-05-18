# King of the Hill: Dwarfs — Developer & QA Reference

## Game Concept

A turn-based, 2–4 player dice game for a single shared device (hot-seat). Players are dwarfs competing to collect **20 gems** first (or be the last dwarf standing). Each turn a player rolls dice, resolves the result, then optionally buys a card from the shop. Cards grant passive bonuses, one-time powers, and active abilities. A **Vault** in the centre of the map is the contested high-value position: the occupant earns bonus gems each turn but can be attacked and forced out.

Supports human vs. human, human vs. bot, and any mix up to 4 players.

---

## Key Concepts for New Developers

| Concept | Where it lives |
|---|---|
| **TurnPhase** (DICE_ROLL → RESOLUTION → BUY_CARDS → END_TURN) | `autoloads/turn_manager.gd` |
| **PlayerData** (HP, gems, gold, position, status flags, card hand) | `resources/player_data.gd` |
| **Win conditions** (20 gems, last standing, draw) | `autoloads/player_manager.gd` |
| **Card effects catalog** | `data/card_catalog.gd` |
| **Effect identity enum** | `scripts/cards/card_effect_id.gd` |
| **Effect execution** | `scripts/cards/card_effect_handler.gd` |
| **Bot AI** | `scripts/ai/bot_brain.gd` |
| **Vault logic** | `scripts/game/vault_controller.gd` |

### Autoloads (global singletons)

- `GameManager` — starts/ends a game session; holds `pending_config`
- `PlayerManager` — owns all `PlayerData` instances; emits signals for HP/gem/gold/position changes
- `TurnManager` — drives the phase state machine; emits `turn_started`, `phase_changed`, `turn_ended`
- `CardShop` — manages the visible card slots; handles purchases
- `AudioManager` — SFX playback

---

## Scenes Overview

```
scenes/
  menus/
    main_menu.tscn        ← entry point
    setup_game.tscn       ← configure players (2–4, human/bot, names)
    game_over.tscn        ← winner screen
  game/
    main_game.tscn        ← the whole game loop
  debug/
    card_sandbox.tscn     ← QA tool (see below)
```

### Starting a game manually (without the menu)

`MainGameController._ready()` falls back to a 2-player default (one human "Thorin" + one bot) when `GameManager.pending_config` is empty. Open `main_game.tscn` directly in the editor and hit Play Scene to use this shortcut.

---

## Card Effect System

Effects are categorised by *when* they fire:

| Category | Fires when |
|---|---|
| **Immediate / ONE_TIME** | On card use (consumed) |
| **Passive (turn-start)** | At the beginning of the owner's turn |
| **Passive (turn-end)** | At the end of the owner's turn |
| **Passive (dice)** | After dice roll is finalised |
| **Event-triggered** | On specific game events (damage taken, kill, vault entry, …) |
| **Acquired (stat modifier)** | On purchase; persists as a stat bonus while card is held |
| **Active ability** | Player activates manually during BUY_CARDS phase, costs gold |

Effect IDs are stable enum values in `CardEffectId.Id` — safe to use in tests and assertions.

---

## QA Guide

### Running Unit Tests

Tests use the **GUT** framework. Run them inside the Godot editor:

1. Open the project in Godot 4.
2. Go to **GUT** panel (bottom dock or Scene → Run Tests).
3. Run all tests or select a specific file.

> **Do not run Godot via the CLI** — GUT requires the editor context.

Test files live in `tests/unit/` and are named `test_m<milestone>_<topic>.gd`.

| File | What it covers |
|---|---|
| `test_m1_player_manager.gd` | Player setup, HP, gems, gold, elimination |
| `test_m1_card_shop.gd` | Shop visibility, purchase, reset |
| `test_m2_turn_manager.gd` | Phase transitions, extra turns, repeat turns |
| `test_m3_dice_pool.gd` | Dice rolling, hold/reroll mechanics |
| `test_m3_dice_resolver.gd` | Face → resource mapping |
| `test_m4_vault_controller.gd` | Enter, attack, flee, forced escape |
| `test_m5_*.gd` | Card effect groups (stat mods, event passives, dice, status, gold-spend, special) |
| `test_m6_bot_brain.gd` | Bot decision logic |
| `test_m7_setup_flow.gd` | Game setup / player config |

### Card Effect Sandbox

`scenes/debug/card_sandbox.tscn` lets you trigger any card effect in isolation without playing a full game. Use it to verify visual feedback, signal chains, and edge-case interactions.

### Manual QA Checklist (game flow)

- [ ] Setup screen: add/remove players (2–4), rename, mix human/bot, start
- [ ] Dice roll: roll, hold dice, reroll up to limit, end roll
- [ ] Resolution: gems/gold/hearts apply correctly; claw prompts vault interaction
- [ ] Vault: enter, attack occupant, flee/stay dialog, forced escape
- [ ] Card shop: 3 visible cards refresh correctly; purchase deducts gold; card appears in hand
- [ ] Active abilities panel: buttons appear only for eligible cards during BUY_CARDS phase
- [ ] Pass-device screen: appears between human turns, disappears for bot turns
- [ ] Win condition: 20 gems → game over screen with correct winner
- [ ] Elimination: player dies → skipped in turn order; last standing triggers game over
- [ ] Bot: takes a full turn automatically with simulated delay

### Player State Fields to Watch During QA

```
health / max_health   — current and maximum HP
gems                  — win at 20
gold                  — shop currency
position              — OUTSIDE | AT_VAULT
is_eliminated
damage_reduction
poison_stacks / shrink_stacks / camouflage_active
gold_dodge_active / nimble_dodge_active
```

---

## Android Build

An APK is exported to the repo root as `DwarfKingOfTheHill.apk`. Install via `adb install` or sideload. The game uses a hardcoded card path list (not `DirAccess`) to work around Android asset loading restrictions.
