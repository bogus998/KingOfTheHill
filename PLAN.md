# Dwarf King of the Hill — Godot 4 Implementation Plan

> **First implementation step:** Copy this plan to `PLAN.md` in the project root at
> `/Users/arturboguslawski/Bogus/Projects/Games/King of the hill (dwarfs)/PLAN.md`

## Context
Starting from an empty Godot 4 project (`project.godot` + `icon.svg` only). The game is a dice game similar to King of Tokyo: 2–4 players roll 6 dice up to 3 times per turn, resolve symbols (numbers→gold, gems, claws/attacks, hearts/heal), occupy a central Vault position, and buy cards with gems. First to 20 gold or last standing wins. Supports VS AI and Hot-Seat modes.

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
1. `scenes/menus/main_menu.tscn`
2. `scenes/menus/setup_game.tscn` — mode selector, player count, names
3. `scenes/menus/game_over.tscn` — winner, reason, play again
4. `scenes/ui/pass_device_screen.tscn` for Hot-Seat
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
- [ ] Print player states on game start: names, HP=10, gold=0, gems=0, pos=OUTSIDE
- [ ] Print loaded card deck size: 10 placeholder cards shuffled
- [ ] `PlayerManager.apply_damage(0, 3)` → player 0 HP = 7, signal fired
- [ ] `PlayerManager.add_gold(0, 20)` → triggers `check_win_conditions` → winner declared
- [ ] `CardShop.purchase(0, 0)` → gems deducted, card added to player hand, slot replenished

### M2 — Turn State Machine
- [ ] Output shows: `DICE_ROLL → RESOLUTION → BUY_CARDS → END_TURN` per player turn
- [ ] With 2 players: after END_TURN for player 0, turn switches to player 1
- [ ] Eliminating player 1 → skipped in turn order
- [ ] Vault bonus: if player 0 is AT_VAULT at turn start → +2 gold before DICE_ROLL

### M3 — Dice System
- [ ] Roll button → all 6 dice show random faces (labels update)
- [ ] Click a die → held overlay appears; re-roll → held die unchanged, others reroll
- [ ] After 3 rolls → Roll button disabled
- [ ] DiceResolver: input `[1,1,1,2,3,⚡]` → gold=1, gems=1, claws=0, hearts=0
- [ ] DiceResolver: input `[2,2,2,2,🐾,❤️]` → gold=3 (2+1 extra), claws=1, hearts=1
- [ ] DiceResolver: input `[🐾,🐾,🐾,⚡,⚡,❤️]` → claws=3, gems=2, hearts=1

### M4 — Full 2-Player Game Loop
- [ ] Player 1 rolls claws → vault empty → enters vault, gets +1 gold
- [ ] Player 2 rolls 2 claws → player 1 (at vault) takes 2 damage; HP = 8
- [ ] Escape dialog appears → Flee: player 2 enters vault, player 1 goes outside
- [ ] Escape dialog → Stay: player 1 remains at vault with HP = 8
- [ ] Player at vault rolls hearts → no healing (ignored)
- [ ] Player outside rolls hearts → HP increases, capped at 10
- [ ] Player reaches 0 HP → eliminated, skipped in turn order
- [ ] Only 1 player alive → "last standing" win condition triggers
- [ ] Player accumulates 20 gold → immediate win condition triggers
- [ ] ResolutionPicker shows when multiple symbol groups exist; player-chosen order applied

### M5 — Card Shop
- [ ] 3 cards visible at game start
- [ ] Buy card with enough gems → gems deducted, card added to hand, slot replenished from deck
- [ ] Buy card with insufficient gems → buy button disabled
- [ ] Refresh (2 gems) → 3 new cards visible, 2 gems deducted
- [ ] Refresh with < 2 gems → refresh button disabled
- [ ] PERMANENT card in hand → passive effect active each turn
- [ ] ONE_TIME card → effect fires, card removed from hand
- [ ] Deck exhausted → shop shows fewer than 3 cards, no crash

### M6 — AI Bot
- [ ] Bot turn: 0.8–1.5s delay between each decision (visible in editor)
- [ ] Bot holds Hearts when HP < 6 and outside
- [ ] Bot holds Claws when at vault and HP is low
- [ ] Bot buys cheapest affordable card during BUY_CARDS phase
- [ ] Bot flees vault when HP < 4
- [ ] Full VS AI game (1 human + 1 bot) runs to completion without manual input

### M7 — Menus & Scene Flow
- [ ] Launch game → main menu appears
- [ ] Select VS AI, 2 players → setup screen shows bot count selector
- [ ] Select Hot-Seat, 3 players → enter names for all 3
- [ ] Game starts with correct player count and mode
- [ ] Hot-Seat: "Pass device to [Player X]" screen appears between turns
- [ ] Game over screen shows winner name and reason (gold/elimination/draw)
- [ ] "Play Again" → returns to setup screen; "Main Menu" → returns to main menu

### M8 — Audio & Polish
- [ ] Dice roll → sound plays
- [ ] Die held/unheld → click sound
- [ ] Gold gained → coin sound
- [ ] Damage taken → hit sound
- [ ] Card purchased → buy sound
- [ ] Vault entered/fled → vault sound
- [ ] No visual regressions from Milestones 1–7
