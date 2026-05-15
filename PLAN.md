# Dwarf King of the Hill — Godot 4 Implementation Plan

## Testing Approach

Tests use the **GUT** (Godot Unit Testing) plugin — the standard Godot 4 unit testing framework.

### Installation (one-time)
1. Godot editor → **AssetLib** → search "Gut" → Download & Install
   *(or download v9.x from https://github.com/bitwes/Gut/releases)*
2. **Project → Project Settings → Plugins → Gut → Enable**
3. A GUT panel appears at the bottom of the editor

### Running tests
| Goal | Action |
|---|---|
| Run all tests | GUT panel → **Run All** |
| Run one file | GUT panel → select file → **Run** |
| Run from FileSystem | Right-click test file → **Run Script** (Ctrl+Shift+F5) |
| Headless / CI | `godot --headless -s res://addons/gut/gut_cmdln.gd` |

### File structure
```
tests/
  unit/
	test_m1_player_manager.gd   ← M1: PlayerManager state & signals
	test_m1_card_shop.gd        ← M1: CardShop deck, purchase, refresh
	test_m2_turn_manager.gd     ← M2: phases, next_player, vault bonus, skip
	test_m3_dice_resolver.gd    ← M3: DiceResolver pure logic
	test_m3_dice_pool.gd        ← M3: DicePool roll & hold mechanics
	...one file per system per milestone...
```

### Rules
- Test files named `test_*.gd`, located in `tests/unit/`
- Each class `extends GutTest`
- Each test method named `test_*` — **tests exactly one thing**
- `before_each()` resets all relevant state; no test shares state with another
- Use GUT assertions: `assert_eq`, `assert_true`, `assert_false`, `assert_signal_emitted`
- `watch_signals(obj)` before the action to enable signal assertions
- Test files are **excluded from game exports**
- Production scripts contain **no test code**

---

## Context
Starting from an empty Godot 4 project (`project.godot` + `icon.svg` only). The game is a dice game similar to King of Tokyo: 2–4 players roll 6 dice up to 3 times per turn, resolve symbols (numbers→gold, gems, claws/attacks, hearts/heal), occupy a central Vault position, and buy cards with gems. First to 20 gold or last standing wins. A single setup screen builds the roster: 2–4 players, each typed Human or Bot.

Full GDD: https://www.notion.so/35aeaebd188281cb871ff45f083a4d28

---

## Project Structure

```
res://
├── autoloads/
│   ├── game_manager.gd       ← start/end game, scene transitions, win declaration
│   ├── turn_manager.gd       ← phase state machine, roll count, current player, vault bonus
│   ├── player_manager.gd     ← all player state, damage, gold, gems, elimination, win checks
│   ├── card_shop.gd          ← deck, 3 visible cards, purchase, refresh
│   └── audio_manager.gd      ← SFX/music (thin wrapper)
├── resources/
│   ├── card_data.gd          ← class_name CardData extends Resource
│   └── player_data.gd        ← class_name PlayerData extends Resource
├── data/
│   ├── card_catalog.gd       ← static loader: returns Array[CardData] from res://data/cards/
│   └── cards/                ← .tres files (10 placeholder cards to start)
├── scripts/
│   ├── dice/
│   │   ├── die_controller.gd
│   │   ├── dice_pool_controller.gd
│   │   └── dice_resolver.gd  ← PURE LOGIC, no Node dependency
│   ├── game/
│   │   ├── main_game_controller.gd
│   │   ├── resolution_controller.gd
│   │   └── vault_controller.gd
│   ├── cards/
│   │   ├── card_shop_controller.gd
│   │   └── card_display_controller.gd
│   ├── players/
│   │   ├── player_panel_controller.gd
│   │   └── card_hand_controller.gd
│   └── ai/
│       └── bot_brain.gd
├── scenes/
│   ├── menus/
│   │   ├── main_menu.tscn
│   │   ├── setup_game.tscn
│   │   └── game_over.tscn
│   ├── game/
│   │   └── main_game.tscn    ← root game scene
│   ├── board/
│   │   └── vault_area.tscn
│   ├── dice/
│   │   ├── die.tscn
│   │   └── dice_pool.tscn
│   ├── cards/
│   │   ├── card_display.tscn
│   │   └── card_shop.tscn
│   ├── players/
│   │   ├── player_panel.tscn
│   │   └── card_hand.tscn
│   └── ui/
│       ├── hud.tscn
│       ├── action_bar.tscn
│       ├── pass_device_screen.tscn
│       ├── resolution_picker.tscn
│       └── escape_dialog.tscn
└── assets/
	├── fonts/
	├── textures/ (dice faces, card back, UI icons)
	└── audio/ (sfx/, music/)
```

---

## Key Data Structures

### `resources/card_data.gd`
```gdscript
class_name CardData extends Resource
@export var card_name: String
@export var description: String
@export var gem_cost: int
@export var card_type: CardType   # enum ONE_TIME / PERMANENT
@export var card_icon: Texture2D
@export var effect_id: String     # maps to Callable in CardEffectHandler dict
```

### `resources/player_data.gd`
```gdscript
class_name PlayerData extends Resource
@export var player_name: String
@export var health: int = 10
@export var gold: int = 0
@export var gems: int = 0
@export var position: PlayerPosition  # enum AT_VAULT / OUTSIDE
@export var is_eliminated: bool = false
@export var cards_in_hand: Array[CardData] = []
@export var is_bot: bool = false
```

**PlayerData is runtime-only** — never saved to .tres. Only CardData lives on disk.

---

## Turn Phase Flow
```
TurnManager.next_player()
  ├── if vault player → award +2 gold (before dice)
  ├── if Hot-Seat → show PassDeviceScreen, wait ReadyButton
  └── phase = DICE_ROLL

DICE_ROLL (up to 3 rolls, player holds dice between rolls)
  → after 3rd roll OR player stops early → phase = RESOLUTION

RESOLUTION (player chooses symbol order via ResolutionPicker)
  Numbers → gold (≥3 matching: face_value + extra_count)
  Gems ⚡ → +1 gem each
  Claws 🐾 → vault entry / deal damage / escape dialog
  Hearts ❤️ → +1 HP each (ignored if AT_VAULT)
  → phase = BUY_CARDS

BUY_CARDS
  → buy 0+ cards, optionally refresh pool (2 gems)
  → phase = END_TURN → TurnManager.next_player()
```

---

## Autoload Singleton Responsibilities

| Autoload | Key Signals | Key Methods |
|---|---|---|
| `GameManager` | `game_started`, `game_ended(winner, reason)` | `start_game(config)`, `declare_winner()` |
| `TurnManager` | `phase_changed(phase)`, `turn_started(idx)` | `advance_phase()`, `next_player()` |
| `PlayerManager` | `player_damaged`, `gold_changed`, `player_eliminated` | `apply_damage()`, `add_gold()`, `check_win_conditions()` |
| `CardShop` | `shop_updated(cards)`, `card_purchased` | `purchase()`, `refresh_pool()` |
| `AudioManager` | — | `play_sfx(name)`, `play_music(name)` |

**Registration order in project.godot** (top→bottom): AudioManager, PlayerManager, CardShop, TurnManager, GameManager.

---

## Signal Architecture (Key Decouplings)

```
TurnManager.phase_changed → MainGameController (show/hide panels)
TurnManager.turn_started  → VaultController (+2 gold), BotBrain (if is_bot)
PlayerManager.player_damaged → PlayerPanelController, VaultController (escape dialog?)
PlayerManager.gold_changed  → PlayerPanelController, check_win_conditions
PlayerManager.player_eliminated → TurnManager (skip), check_win_conditions
VaultController.vault_fled → PlayerManager (update positions for both players)
DicePoolController.roll_completed → TurnManager (increment roll_count)
GameManager.game_ended → MainGameController (show GameOver overlay)
```

UI panels **never call PlayerManager directly** — they only react to signals.

---

## Build Milestones

### Milestone 1 — Data Layer
1. `resources/player_data.gd` + `resources/card_data.gd` with enums
2. `autoloads/player_manager.gd` — setup, apply_damage, add_gold, check_win_conditions
3. `data/card_catalog.gd` — static loader
4. `autoloads/card_shop.gd` — shuffle, replenish, purchase, refresh
5. 10 placeholder `.tres` CardData files
6. Register autoloads in project.godot

### Milestone 2 — Turn State Machine
1. `autoloads/turn_manager.gd` — phase enum, advance_phase, next_player, roll_count
2. `autoloads/game_manager.gd` — start_game, declare_winner, scene transitions
3. Minimal `main_game.tscn` + `main_game_controller.gd` wiring phase changes to Output

### Milestone 3 — Dice System
1. `resources/die_face.gd` (enum) or inline enum in die_controller
2. `scripts/dice/dice_resolver.gd` — pure logic: faces in → ResolveResult out
3. `scripts/dice/die_controller.gd` — face, ACTIVE/HELD state, toggle_hold, roll
4. `scenes/dice/die.tscn` — PanelContainer + FaceLabel placeholder + DieController
5. `scripts/dice/dice_pool_controller.gd` — manages 6 dice, roll_active_dice, get_all_faces
6. `scenes/dice/dice_pool.tscn` — HBoxContainer with 6 Die instances
7. Connect roll_completed → print ResolveResult

### Milestone 4 — Full 2-Player Game Loop (no polish)
1. `scripts/game/vault_controller.gd` + `scenes/board/vault_area.tscn`
2. `scripts/game/resolution_controller.gd` — drives RESOLUTION phase step by step
3. `scenes/ui/escape_dialog.tscn` — Flee/Stay buttons
4. `scenes/ui/resolution_picker.tscn` — symbol order selection
5. Minimal `scenes/players/player_panel.tscn` (labels only)
6. `scripts/players/player_panel_controller.gd`
7. `scenes/ui/hud.tscn` + `scenes/ui/action_bar.tscn`
8. Wire all signals end-to-end; full 2-player game runs to win condition

### Milestone 5 — Card Shop
1. `scenes/cards/card_display.tscn` + `card_display_controller.gd`
2. `scenes/cards/card_shop.tscn` + `card_shop_controller.gd`
3. `CardEffectHandler` dictionary: `effect_id → Callable` (placeholder effects for now)
4. `scenes/players/card_hand.tscn` + `card_hand_controller.gd`
5. Show/hide shop only during BUY_CARDS phase

### Milestone 6 — AI Bot
1. `scripts/ai/bot_brain.gd`
   - `decide_holds(faces, player_data) -> Array[bool]`
   - `decide_buy(visible_cards, gems) -> int`
   - `decide_flee(player_data) -> bool`
   - `get_thinking_delay() -> float` — randf_range(0.8, 1.5)
2. Wire TurnManager.turn_started → BotBrain coroutine when is_bot
3. VS AI mode fully playable

### Milestone 7 — Menus & Full Scene Flow
1. `scenes/menus/main_menu.tscn` — single "Start Game" entry point
2. `scenes/menus/setup_game.tscn` — unified roster screen: add/remove players (2–4), per-player Human/Bot type, editable names (bots default `bot_#`)
3. `scenes/menus/game_over.tscn` — winner, reason, play again
4. `scenes/ui/pass_device_screen.tscn` — shown before every human turn
5. Set `main_menu.tscn` as main scene in project.godot

### Milestone 8 — Audio, Art & Polish
1. `autoloads/audio_manager.gd` + SFX hooks on key events
2. Real die face textures, card art placeholders
3. Tweens/animations: dice roll shake, gold counter increment, damage flash
4. Custom Godot Theme resource for all Controls

---

## Assets: Placeholder Strategy
All milestones 1–7 use **zero image files**:
- Die faces → `Label` nodes with text: `"1"`, `"2"`, `"3"`, `"⚡"`, `"🐾"`, `"❤️"`
- Dice held state → tinted `ColorRect` overlay
- Cards → `PanelContainer` with colored background + `Label` nodes
- Player panels → flat `PanelContainer` with a unique `StyleBoxFlat` color per player
- Icons (HP, gold, gems) → `Label` with emoji: `"❤️"`, `"🪙"`, `"💎"`
- The Vault → `ColorRect` with label `"THE VAULT"`

Placeholder assets are wired exactly the same way real assets would be — just swap `Texture2D` exports later.

### Recommended Free Asset Packs (for Milestone 8)
When ready to replace placeholders, these CC0/free packs are well-suited:

| Pack | Source | Best for |
|---|---|---|
| **Kenney Dice Pack** | kenney.nl/assets/dice-kit | Dice faces (PNG spritesheets, multiple styles) |
| **Kenney Game Icons** | kenney.nl/assets/game-icons | HP, gold, gem, vault UI icons |
| **Fantasy Wooden GUI** | itch.io/search?q=fantasy+wooden+gui | Panel and card frame art |
| **RPG Card Pack** (Hyper Grotesk) | itch.io/search?q=rpg+card+pack | Card backs, card frames |
| **Dwarf / Fantasy SFX** | freesound.org (CC0 filter) | Dice roll, coin, hit, heal sounds |
| **OpenGameArt Fantasy Music** | opengameart.org | Background loops |

All Kenney assets are CC0 (no attribution required). itch.io packs vary — check license before use.

---

## Cards: Placeholder Approach
- Start with 10 `.tres` placeholder cards (mix of ONE_TIME and PERMANENT types)
- `CardEffectHandler` uses `effect_id` string key → Callable — new card effects are added without touching existing code
- Full 66-card design is a separate future task

---

## Verification (per milestone)

### M1 — Data Layer
GUT files: `tests/unit/test_m1_player_manager.gd`, `tests/unit/test_m1_card_shop.gd`
- [ ] Initial state: HP=10, gold=0, gems=0, pos=OUTSIDE for all players
- [ ] `apply_damage` reduces HP, emits `player_damaged`, eliminates at 0
- [ ] `apply_heal` restores HP (capped at 10, ignored at vault)
- [ ] `add_gold` emits `gold_changed`; reaching 20 emits `win_condition_met`
- [ ] `spend_gems` returns false and makes no deduction when insufficient
- [ ] Last player standing emits `win_condition_met`
- [ ] CardShop loads 10 cards; 3 visible; purchase deducts gems and replenishes slot
- [ ] Refresh costs 2 gems and emits `shop_updated`

### M2 — Turn State Machine
GUT file: `tests/unit/test_m2_turn_manager.gd`
- [ ] Starts at player 0, DICE_ROLL, roll_count=0
- [ ] `advance_phase` steps DICE_ROLL → RESOLUTION → BUY_CARDS → END_TURN
- [ ] `advance_phase` does nothing when `is_game_active` is false
- [ ] `next_player` moves to player 1, resets phase to DICE_ROLL, resets roll_count
- [ ] `next_player` wraps back to player 0 after all players have gone
- [ ] Vault player receives +2 gold at the start of their turn
- [ ] Eliminated player is skipped in turn order
- [ ] Correct signals emitted: `phase_changed`, `turn_started`, `turn_ended`

### M3 — Dice System
GUT files: `tests/unit/test_m3_dice_resolver.gd`, `tests/unit/test_m3_dice_pool.gd`

**Automated (GUT):**
- [ ] `DiceResolver`: `[1,1,1,2,3,⚡]` → gold=1, gems=1, claws=0, hearts=0
- [ ] `DiceResolver`: `[2,2,2,2,🐾,❤️]` → gold=3 (2 + 1 extra), claws=1, hearts=1
- [ ] `DiceResolver`: `[3,3,3,3,3,3]` → gold=6 (3 + 3 extra)
- [ ] `DiceResolver`: `[1,2,3,⚡,🐾,❤️]` → gold=0 (no triple), gems=1, claws=1, hearts=1
- [ ] `DiceResolver`: `[🐾,🐾,🐾,⚡,⚡,❤️]` → claws=3, gems=2, hearts=1
- [ ] `DicePool`: all 6 dice start ACTIVE; `roll_active_dice()` changes their faces
- [ ] `DicePool`: held die face unchanged after re-roll; ACTIVE dice change
- [ ] `DicePool`: `toggle_hold()` switches die between ACTIVE and HELD
- [ ] `DicePool`: emits `roll_completed` with correct face array after roll

**Manual (play in editor):**
- [ ] Roll button → die face labels update visually
- [ ] Held die shows tinted overlay; un-hold removes it
- [ ] Roll button disabled after 3rd roll

### M4 — Full 2-Player Game Loop
GUT file: `tests/unit/test_m4_vault_controller.gd`

**Automated (GUT):**
- [ ] `VaultController`: enter vault when empty → occupant set, +1 gold awarded, signal fired
- [ ] `VaultController`: attack from outside → vault player takes claw-count damage
- [ ] `VaultController`: attack at vault → all outside players take claw-count damage
- [ ] `VaultController`: `handle_flee()` → attacker becomes occupant, previous occupant goes OUTSIDE
- [ ] `VaultController`: `handle_stay()` → occupant unchanged after choosing to stay
- [ ] `VaultController`: entering occupied vault via claw is not possible (must use flee path)

**Manual (play in editor):**
- [ ] Escape dialog appears when vault player takes damage; Flee/Stay buttons work
- [ ] ResolutionPicker shows symbol groups; chosen order is applied
- [ ] Hearts ignored for vault player; applied for outside player
- [ ] Player at 0 HP is eliminated and skipped
- [ ] 20 gold or last-standing win condition ends the game

### M5 — Card Shop
GUT file: `tests/unit/test_m5_card_effects.gd`

**Automated (GUT):**
- [ ] `CardEffectHandler`: `gain_gold_1` → player gold +1
- [ ] `CardEffectHandler`: `heal_3` → player HP +3 (capped at 10)
- [ ] `CardEffectHandler`: `gain_gems_2` → player gems +2
- [ ] `CardEffectHandler`: `damage_all_2` → all other players take 2 damage
- [ ] `CardEffectHandler`: `gem_per_turn_1` passive fires each turn start for owner
- [ ] ONE_TIME card removed from hand after effect triggers
- [ ] PERMANENT card remains in hand; passive effect active while held
- [ ] Shop shows < 3 cards when deck is exhausted — no crash

**Manual (play in editor):**
- [ ] Buy button disabled when gems insufficient
- [ ] Refresh button disabled when gems < 2
- [ ] Card shop hidden outside BUY_CARDS phase
- [ ] Purchased permanent cards appear in player hand panel

### M6 — AI Bot
GUT file: `tests/unit/test_m6_bot_brain.gd`

**Automated (GUT):**
- [ ] `BotBrain.decide_holds()`: holds Hearts when HP < 6 and OUTSIDE
- [ ] `BotBrain.decide_holds()`: holds Claws when AT_VAULT and HP is low
- [ ] `BotBrain.decide_holds()`: holds matching numbers when gold needed
- [ ] `BotBrain.decide_buy()`: returns cheapest affordable card index
- [ ] `BotBrain.decide_buy()`: returns -1 when no card is affordable
- [ ] `BotBrain.decide_flee()`: returns true when HP < 4 at vault
- [ ] `BotBrain.decide_flee()`: returns false when HP ≥ 4
- [ ] `BotBrain.get_thinking_delay()`: returns value in range [0.8, 1.5]

**Manual (play in editor):**
- [ ] Bot turn completes with visible 0.8–1.5s delay between actions
- [ ] Full VS AI game (1 human + 1 bot) runs to completion without manual input

### M7 — Menus & Scene Flow
GUT files: `tests/unit/test_m7_setup_flow.gd`, `tests/unit/test_m7_hud.gd`

**Automated (GUT):**
- [ ] Setup screen starts with 1 Human player row
- [ ] `add_player()` adds rows and is capped at 4
- [ ] `remove_player()` removes rows; the last remaining row cannot be removed
- [ ] A Bot-typed row's default name is `bot_#`
- [ ] `get_player_configs()` reports correct name + is_bot per row
- [ ] Blank name field falls back to the type-appropriate default name
- [ ] HUD builds exactly one player panel per configured player (2, 3, and 4)

**Manual (launch game, no editor):**
- [ ] Launch → main menu shows a single "Start Game" button
- [ ] Start Game → setup screen opens with one Human row
- [ ] "Add Player" adds rows (disabled at 4); "Remove" disabled with one row left
- [ ] "Start Game" disabled until ≥2 players
- [ ] Switching a row to Bot defaults its name to `bot_#`; name stays editable
- [ ] 3- and 4-player games show that many player panels and card hands
- [ ] "Pass device to [Player X]" overlay appears before every human turn
- [ ] Game over screen shows winner name and reason (gold / elimination / draw)
- [ ] "Play Again" → returns to setup; "Main Menu" → returns to main menu
- [ ] No crashes transitioning between any two scenes

### M8 — Audio & Polish
*No GUT tests — audio, visuals, and animations verified by observation.*

**Manual (play in editor):**
- [ ] Dice roll → roll sound plays
- [ ] Die held/un-held → click sound plays
- [ ] Gold gained → coin sound plays
- [ ] Damage taken → hit sound plays
- [ ] Card purchased → buy sound plays
- [ ] Vault entered or fled → vault sound plays
- [ ] Dice shake on roll; gold counter animates on gain; damage flash on hit
- [ ] All Controls use the custom Theme (no default grey boxes)
- [ ] No visual regressions from Milestones 1–7
