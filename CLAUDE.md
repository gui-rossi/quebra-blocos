# quebra-blocos

A mobile block puzzle game in **Godot 4.7** (GDScript, "Mobile" renderer, 720×1280 portrait base viewport,
`canvas_items` stretch with `expand` aspect). It's inspired by Block Blast, not a copy: drag pieces from a 3-slot
tray onto a 10×12 grid, clear full rows and columns, chain clears for a score multiplier with a combo timer, and use
power-ups like the bomb.

## Working on this repo

- **Godot isn't available in the Claude environment.** Nothing can be run or tested here. Every change has to be
  checked by the owner in the Godot editor, so keep that in mind and say so when reporting work.
- **Build UI in code, not in `.tscn` files.** Most widgets are created in `_ready()`, so scene files stay small and
  valid when edited by hand. When a `.tscn` must change, keep its existing `uid` and `unique_id` values. New scenes
  can leave out the `uid` (Godot assigns one).
- **Git identity:** commits use the repo-local identity `guirossi <guizo.rossi@gmail.com>` (set in `.git/config`).
- **Pushing:** WSL git has no GitHub credentials, so push with Windows git: `git.exe push origin <branch> <tag>`.
- **Checkpoints:** each milestone is an annotated git **tag** named `checkpoint-NN-<name>` on the work branch
  (currently `enhancements`), pushed to GitHub. Follow-up fixes for a milestone go in a new commit, then the tag is
  moved with `git tag -f -a` and force-pushed with `git.exe push --force origin <tag>`. `git tag -l` shows the next
  number.
- **`.import` files:** Godot creates them when the project opens (one per asset, including every music track). Commit
  them when they show up.

## Checkpoints so far

| Tag | What it added |
|---|---|
| `checkpoint-01-enhancements` | Main menu, pause and options menus, Settings and SaveGame, generated sound effects, top tray HUD (animated score, best score, multiplier badge with a combo ring), placement and line-clear effects, score popups, game over, save and resume |
| `checkpoint-02-visuals` | Gradient background, rounded board panel, beveled glossy blocks in palette colors, soft tray slots, unplayable pieces dimmed, grid-size dragging with a ghost preview and lines-to-clear highlight, pieces held by their center, tray pieces drawn at screen resolution |
| `checkpoint-03-hud-music` | Gear and multiplier badge aligned with the board edges, badge font shrinking with digits, settings saved on every change, public-domain classical music (MusicPlayer) |
| `checkpoint-04-music-player` | More public-domain tracks (14 total), a music player in Options (now playing, progress and time, previous and next) |
| `checkpoint-05-backpack` | Backpack bar with 3 power-up slots (slots 2 and 3 unlock for good at 250K and 750K), compact score numbers (75.3K, 1.25M), music paused when turned off, unused sound controls hidden |

## Project layout

```
configs/      game data and global state (autoloads + plain helper scripts)
managers/     gameplay systems (grid, drag and drop, combo timer, sound effects, music)
scenes/
  main.tscn/gd     the game screen, wires everything together
  blocks/          a single block (tile) and how it's drawn
  controls/        top tray (HUD), bottom tray (3 piece slots), a tray piece
  powerups/        the bomb and its effects
  effects/         particle bursts and floating text
  ui/              menus, HUD widgets, backpack, shared UI styling
assets/music/  public-domain music tracks + CREDITS.md (source and license of each)
```

### Autoloads (order matters, see `project.godot`)

| Name | Script | Role |
|---|---|---|
| `GameConfig` | `configs/game_config.gd` | Tuning values (points, bomb radius and fuse, backpack unlock scores) and run state (`current_score_multiplier`, `cell_size`) |
| `ShapeDefinitions` | `configs/shape_definitions.gd` | Every piece shape (cell offsets) and every power-up's data (`POWERUPS`) |
| `Settings` | `configs/settings.gd` | Player options and stats in `user://settings.cfg`, creates the `SFX` and `Music` audio buses, `vibrate()` |
| `Sfx` | `managers/sfx.gd` | Sound effects synthesized in code at startup (no files), a pool of players on the SFX bus |
| `SaveGame` | `configs/save_game.gd` | The run in progress as JSON in `user://run.json` (versioned) |
| `MusicPlayer` | `managers/music_player.gd` | Shuffled playlist with crossfades on the Music bus, previous and next |

`Settings` must load before `Sfx` and `MusicPlayer`: it creates the audio buses they play on. A player set to a bus
that doesn't exist yet silently falls back to Master, so mute and volume wouldn't apply.

Plain helper scripts (not autoloads) are loaded with `const X = preload(...)`: `configs/palette.gd` (every color),
`configs/number_format.gd`, `scenes/ui/ui_style.gd`.

## Architecture decisions

### Data-driven pieces and power-ups
- Shapes and power-ups live in `configs/shape_definitions.gd`. A power-up entry has `cells`, `spawn_chance`,
  `tray_size_ratio`, `drag_size_cells` and `drag_alpha`. Adding a power-up starts with an entry there.
- Tray pieces (`scenes/controls/randomized_block.gd`) carry the per-piece values the drag controller reads:
  `shape_cells`, `shape_name` / `powerup_name`, `piece_color`, `drag_size_cells` (resize to N grid cells while
  dragged), `drag_alpha`, `body_size`, `container_rest_scale` and `container_rest_position`.
- **The drag interface is duck-typed.** Anything with those fields and a `ShapeContainer` Node2D child can be
  dragged: tray pieces and backpack slots (`scenes/ui/backpack_slot.gd`) both are. `drag_controller.gd` doesn't care
  where a piece comes from, except that tray power-ups can also be dropped into the backpack.
- **Still bomb-specific:** the grid highlight, `can_place_bomb` and `detonate_bomb` are separate code paths behind
  `is_bomb`. A second power-up would ideally give each power-up scene its own `highlight`, `can_place` and
  `activate`.

### Drawing
- **Blocks are drawn, not textured.** `scenes/blocks/block_visual.gd` draws the beveled, glossy tile with
  StyleBoxFlat layers. Use `block_space.block_color` for the color and keep `modulate` free for effects (flashes,
  fades, ghost transparency). `empty = true` draws a recessed empty grid cell.
- **Draw at screen resolution.** Tray slots are scaled up about 3.5×. Drawing small and scaling up gives 1px corners
  and stretched edge smoothing, so a tray piece's `ShapeContainer` uses scale `1/k` (k = the slot's screen scale) and
  is built k times bigger, and the slot ring is drawn with `draw_set_transform` back to screen pixels. That's why
  `bottom_tray.scale_randomized_blocks()` must run **before** pieces are built (see `main.gd`).
- **All colors are in `configs/palette.gd`.** Piece colors are picked at random from `PIECE_COLORS`.
- **The board panel** is drawn in `grid_manager._draw()`, under all the cells. `get_board_rect()` gives its rectangle,
  and the top tray uses it to line the gear and badge up with the board's edges.

### Screen layout (`scenes/main.gd`)
- Top to bottom: top tray (10% of the height), board, backpack bar (7.5%), bottom tray (20%). The grid gets what's
  left (`grid_manager.set_reserved_space`), with square cells sized by the tighter of width and height.
- The HUD and the bottom tray have no solid bars: everything floats on the gradient background
  (`scenes/ui/background.gd`).

### Gameplay flow
- **Game over:** after every drop (`drag_controller.piece_dropped`), `main.gd` checks whether any tray piece fits
  anywhere (`grid_manager.can_fit_anywhere`). Power-ups always fit, and anything in the backpack keeps the game going.
  For the bomb it first waits for `grid_manager.bomb_detonated`, because cells only free up once the fuse burns down.
- **The combo multiplier** goes up with each cleared line (`grid_manager.cleared_row_or_column`). It resets in
  `main.gd` on `timer_manager.combo_expired`; the HUD only displays it.
- **Line clears** free their cells immediately, then animate the tiles in a wave from where the piece landed.
- **Pieces that don't fit** are dimmed after every move (`main._update_playable`).

### Saving
- **Settings** (`user://settings.cfg`) are saved as soon as an option changes. They also hold `best_score` and
  `backpack_slots`, the number of unlocked backpack slots (permanent unlocks).
- **The run** (`user://run.json`) holds the board, the tray slots (shape or power-up by name, plus color), the backpack
  contents, score, multiplier and combo time left. It's saved after every drop, on pause, when going to the menu, and
  when the app goes to the background. It's cleared on game over or New game. Bump `SaveGame.VERSION` when the format
  changes, and older saves are then ignored.

### Backpack
- Slot 1 is always open. `GameConfig.backpack_unlock_scores = [0, 250000, 750000]`. Reaching a score in any game
  unlocks that slot for good (`Settings.backpack_slots`), and an existing best score counts too.
- While a tray power-up is dragged, free slots glow. Dropping on one (with some margin around it) stores the power-up
  and uses up the tray piece, like placing it. A stored power-up is dragged onto the grid the same way as from the
  tray, and returns to its slot if dropped elsewhere.

### Audio
- **Sound effects** are generated in code (`managers/sfx.gd`). The line-clear chime gets higher with the multiplier.
- **Music** (`managers/music_player.gd`):
  - It plays a shuffled playlist with a 2.5s crossfade (0.4s when skipping). "Previous" restarts the track if it has
    played for more than 3s.
  - When music is off it **pauses** the players and stops processing, instead of muting them, so it uses no CPU.
  - It keeps playing while the game is paused.
- **Music licensing rule:** a composition being old isn't enough, because each recording has its own copyright. Only
  use **CC0 or public domain recordings**, for example Musopen releases or US military bands, which are US
  government works. Check each file's license, list it in `assets/music/CREDITS.md`, and add it to
  `MusicPlayer.TRACKS`.
- **Licensing caveats in the playlist:**
  - Clair de lune has an unclear CC note.
  - Rondo alla Turca is rendered from a MIDI, so it sounds synthetic.
  - Tico-Tico no Fubá may still be protected in the US. It's included at the owner's decision.
- **Size:** the music adds about 69 MB. If app size matters, compress or drop Clair de lune and William Tell first.

### UI conventions
- **Menus are CanvasLayers on layer 20** with `PROCESS_MODE_ALWAYS`. Opening the pause menu sets
  `get_tree().paused`, which also stops drag input and the combo timer.
- **Buttons come from `UiStyle.button()`**, which gives the rounded look, the press squish, the click sound and the
  vibration.
- **Icons are drawn in code** (gear, previous/next, padlock) so no icon files or font glyphs are needed. The default
  font may not have symbols like ⚙ or ▶.
- **The backpack icon is a sprite**, `assets/ui/backpack.png`. It's original art: a glossy 3D rucksack with a dark
  outline (top straps, side pockets, rounded flap, front pocket) and a faceted blue diamond on its centre strap. It's
  variant `b5` of `tools/backpack_icons.py` (pure Python, no dependencies). That script also keeps the other variants
  that were tried (`b` to `b4`). Run `python3 tools/backpack_icons.py assets/ui b5` and rename
  `backpack_option_b5.png` to `backpack.png` to rebuild it. `tools/` has a `.gdignore`, so Godot
  skips it.
- **Scores are shown with `NumberFormat.compact()`**: full below 10,000, then 75.3K, 253K, 1.25M. Values are cut
  down, never rounded up.

## Plans for the future

### Next up: language support (en, pt_BR, es)
- **Translations:** `localization/strings.csv` with keys and `en`, `pt_BR` and `es` columns, registered under Project
  Settings → Localization. Every visible string becomes a key. Controls translate their `text` on their own, and
  strings with values use `tr("KEY") % value`.
- **Detection:** on first launch the game follows the phone's language (`OS.get_locale()`). Godot picks the closest
  translation we ship, and anything we don't have falls back to English.
- **Language option** in Options: "Automatic" (the default, follows the phone) followed by each language written in
  its own language (English, Português (Brasil), Español). It's saved in `Settings` and applies right away, with no
  restart.
- **Watch for:** longer text (Portuguese and Spanish run about 30% longer, so check button and HUD widths). Music
  titles stay untranslated. Languages outside Latin, Cyrillic and Greek would need extra Noto fonts, and
  right-to-left languages are out of scope for now.

### Piece randomizer
- **Difficulty curve:** spawn smaller pieces first, then bring in bigger ones as the game goes on. Possible measures
  of progress: score, pieces placed, or lines cleared. Weight each shape in `ShapeDefinitions.SHAPES` by its size
  (cell count) and shift the weights as progress grows, instead of the current uniform `get_random_shape_name()`.
- **Every batch of 3 tray pieces must be 3 different pieces** (no repeated shape in the same batch). Roll the batch
  as a whole in `bottom_tray`, not one slot at a time.
- **At most 1 power-up per batch of 3.** Today each slot rolls `spawn_chance` on its own
  (`ShapeDefinitions.roll_powerup_name`), so 2 or 3 bombs can show up together.
- The testing shortcut in `randomize_shape()` (always `square_3x3`) goes away as part of this.

### Power-ups
- **More power-ups.** Add them as entries in `ShapeDefinitions.POWERUPS`. This is a good time to finish the
  per-power-up behaviour (`highlight`, `can_place`, `activate` on each power-up scene) so `drag_controller` and
  `grid_manager` stop branching on `is_bomb`.
- **Make the bomb smaller.** Its blast is `GameConfig.bomb_radius = 4`, a rounded 9×9 area on a 10×12 board. Confirm
  with the owner whether "smaller" means the blast area, the sprite, or both.

## Known leftovers
- `randomize_shape()` in `randomized_block.gd` has a testing shortcut that always returns `square_3x3`. Remove it to
  get normal piece variety.
- The `.import` files for the music aren't committed yet.
