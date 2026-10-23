# Blockpack

(The repo and folder are still called `quebra-blocos`, the game's original name.)

A mobile block puzzle game in **Godot 4.7** (GDScript, "Mobile" renderer, 720×1280 portrait base viewport,
`canvas_items` stretch with `expand` aspect). It's inspired by Block Blast, not a copy: drag pieces from a 3-slot
tray onto a 10×12 grid, clear full rows and columns, chain clears for a score multiplier with a combo timer, and use
power-ups (bomb, laser, prism, booster, hourglass).

## Working on this repo

- **Godot isn't available in the Claude environment.** Nothing can be run or tested here. Every change has to be
  checked by the owner in the Godot editor, so keep that in mind and say so when reporting work.
- **Build UI in code, not in `.tscn` files.** Most widgets are created in `_ready()`, so scene files stay small and
  valid when edited by hand. When a `.tscn` must change, keep its existing `uid` and `unique_id` values. New scenes
  can leave out the `uid` (Godot assigns one).
- **Git identity:** commits use the repo-local identity `guirossi <guizo.rossi@gmail.com>` (set in `.git/config`).
- **Pushing:** WSL git has no GitHub credentials, so push with Windows git: `git.exe push origin <branch> <tag>`.
- **Commit and push as soon as a feature or fix is done, without waiting to be asked.** The owner tests from the
  remote branch after the push. **Update this file in every push** (checkpoint table, architecture notes, plans).
- **Checkpoints:** each milestone is an annotated git **tag** named `checkpoint-NN-<name>` on the work branch
  (currently `enhancements`), pushed to GitHub. They're tags, not branches. `git tag -l` shows the next number.
- **How work is organized around checkpoints:**
  1. The owner starts a new checkpoint when they ask for a new feature or milestone ("next checkpoint",
     "checkpoint 8"). Build it, update this file (checkpoint table, architecture notes, plans), commit, create the
     next `checkpoint-NN-<name>` tag, and push the branch and the tag.
  2. The owner tests from the remote. Fixes and tweaks they ask for "on this checkpoint" go in a new commit on the
     same branch. Then the existing tag is moved to it (`git tag -f -a checkpoint-NN-<name> -m "..." HEAD`) and
     force-pushed (`git.exe push --force origin checkpoint-NN-<name>`).
  3. Changes to docs or plans only (this file, README) are folded into the current checkpoint the same way.
  4. Never move an older checkpoint's tag unless the owner asks. A checkpoint is the point to go back to if
     something breaks.
- **`README.md`** explains how to run the game and build a Windows `.exe` or an Android `.apk`/`.aab`. Builds
  go in `build/`, which is gitignored.
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
| `checkpoint-06-languages` | Language support: English, Brazilian Portuguese and Spanish, automatic from the phone's language with a Language option in Options |
| `checkpoint-07-powerups` | Generic power-up system, new laser / prism / booster / rare hourglass (half-speed combo timer for 30s), smaller bomb (radius 2), 5 backpack slots unlocking at 35K / 100K / 250K / 500K (only from scores reached in a game), at most 1 power-up per tray batch, combo multiplier lasts 15s (was 5s) |
| `checkpoint-08-multiplier-trash` | Score multiplier capped at x10, a small fire on the multiplier number from x5 growing to x10 (inside the timer ring), a crown next to the best score, trash can at the end of the backpack bar (any power-up, from the tray or the backpack, for points by rarity), fix for getting stuck with a prism on an empty board and a full backpack |
| `checkpoint-09-refining-sprites` | Power-up sprites (bomb, laser, prism, booster, hourglass) and the trash can redone in the backpack's art style (thick dark outline, soft 3D shading, cast and ground shadows), from `tools/powerup_sprites.py`; broken blocks' fragments fall for a moment, then fly into the score |
| `checkpoint-10-stronger-powerups` | Mega power-ups: dragging a power-up onto another of the same type (tray or backpack, either way) merges them into its mega version (bigger bomb, 3-wide laser, two-color prism, +5 booster, hourglass that stops the combo timer), the destroying ones score x3, golden aura and star badge |

## Project layout

```
configs/      game data and global state (autoloads + plain helper scripts)
managers/     gameplay systems (grid, drag and drop, combo timer, sound effects, music)
scenes/
  main.tscn/gd     the game screen, wires everything together
  blocks/          a single block (tile) and how it's drawn
  controls/        top tray (HUD), bottom tray (3 piece slots), a tray piece
  powerups/        the power-ups' drawings and effects (bomb scene, drawn laser / prism / booster / hourglass)
  effects/         particle bursts and floating text
  ui/              menus, HUD widgets, backpack, shared UI styling
assets/music/  public-domain music tracks + CREDITS.md (source and license of each)
assets/ui/     UI sprites (backpack icon)
assets/powerups/ power-up and trash can sprites (tools/powerup_sprites.py)
assets/icon/   app icon: icon.png (512, project + Play Store), adaptive icon foreground and background (432)
localization/  strings.csv with every visible text in each language
tools/         asset generator scripts (ignored by Godot)
```

### Autoloads (order matters, see `project.godot`)

| Name | Script | Role |
|---|---|---|
| `GameConfig` | `configs/game_config.gd` | Tuning values (points, max multiplier and where the badge catches fire, bomb radius and fuse, booster amount, slow-time speed and length, backpack unlock scores) and run state (`current_score_multiplier`, `cell_size`) |
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
- **Power-ups are generic.** A piece holds a power-up when its `powerup_name` isn't empty, and the drag controller
  only calls `grid_manager.show_powerup_highlight`, `can_place_powerup` and `activate_powerup(key, visual, col, row)`.
  What each one does is a `match` on the key in `grid_manager.gd` ("Power-ups" section):
  - **bomb:** a round blast, `GameConfig.bomb_radius` (2, a 5×5 area without the corners).
  - **laser:** clears the target's whole row and column.
  - **prism:** clears every block with the target's color, and can only be dropped on a block.
  - **booster:** goes anywhere, raises the multiplier by `GameConfig.booster_multiplier` and refills the combo timer.
  - **hourglass (rare, 1.5%):** goes anywhere. For `GameConfig.slow_time_duration` (30) real seconds the combo timer
    runs at `GameConfig.slow_time_factor` (0.5, half speed), and the badge's ring turns icy blue. The grid emits
    `slow_time_used(duration, factor)` and `main.gd` calls `timer_manager.slow_down()`. Using another one while
    one is on keeps the longer time left and the stronger factor. The time left and the factor are saved with the run.
- **The visuals:** each power-up's `visual` in `POWERUPS` is a scene or script with `fit_to(diameter)`,
  `start_idle()` and `activate(target)` (fly to the target, play a flair, free itself). The grid applies the effect
  after `activate` ends. The bomb is a scene (sprite `bomb_body.png` with a `Line2D` fuse and an outline `Line2D`
  under it), and the others extend `scenes/powerups/powerup_visual.gd`, which draws their sprite (`sprite`) over a
  soft halo (`halo_color`) that breathes while idle; subclasses only add extras (the booster's "+2") and their flair.
  Pieces get theirs from `ShapeDefinitions.make_powerup_visual()`.
- **Adding a power-up:** an entry in `POWERUPS`, a visual, and a case in `get_powerup_area`, `can_place_powerup` and
  `activate_powerup`, plus its mega version (below).
- **Mega power-ups (merging):** each base power-up has `"merges_into": "mega_<key>"`. Its mega entry in `POWERUPS`
  has `"effect": "<key>"`, `"mega": true` and `spawn_chance` 0, so it only comes from merging and doesn't merge again.
  The grid matches on `ShapeDefinitions.get_effect(key)` and reads `is_mega(key)` for the stronger numbers in
  `GameConfig.mega_*`:
  - **mega bomb:** radius 4 (9×9 with rounded corners).
  - **mega laser:** 3 rows and 3 columns, centered on the target.
  - **mega prism:** the target's color plus the most common other color on the board.
  - **mega booster:** +5 to the multiplier (still capped at x10).
  - **mega hourglass:** the combo timer stops (factor 0) for 30s.
  - Blocks broken by a mega bomb, laser or prism score `GameConfig.mega_score_bonus` (3) times more, with a
    "Mega x3!" popup. Mega trash scores are 3× the base ones.
  - **Merging** is in `drag_controller.gd` ("Merging" section). It's checked after the trash can and before
    storing in the backpack: the dragged power-up dropped on a tray piece or a backpack slot holding the same key
    (`_merge_target_at`) is used up, and the target becomes the mega version (`randomized_block.upgrade_powerup()`
    or `backpack_slot.store()`). Possible targets pulse with a gold ring (`merge_ready` on tray pieces,
    `backpack.set_merge_ready`) and light up when hovered.
  - **Look:** `make_powerup_visual()` sets `mega` on the visual (the booster then shows "+5") and adds two
    `scenes/powerups/mega_aura.gd` children: a pulsing gold glow with circling sparkles behind it, and a gold star
    badge in front. They size themselves from the visual's `diameter`, so they work for the bomb scene too. There
    are no separate mega sprites yet.
- **Spawning:** one roll per tray slot against the sum of all `spawn_chance` values, then a pick weighted by chance
  (`roll_powerup_name`). **At most 1 power-up per batch of 3:** `bottom_tray._roll_batch()` rolls the slots in a
  random order, and once one gets a power-up the others can only get shapes.

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
- **Game over:** after every drop (`drag_controller.piece_dropped`), `main.gd` checks whether any tray shape fits
  anywhere (`grid_manager.can_fit_anywhere`). Any power-up left, in the tray or the backpack, keeps the game going:
  even one with nowhere to go on the board (a prism needs a block, so not on an empty board) can be dropped in the
  trash can, which uses up its slot. That's what fixed getting stuck with only a prism in the tray, an empty board and
  a full backpack. For a power-up it first waits for `grid_manager.powerup_finished`, because cells only free up once
  its animation is done.
- **The combo multiplier** goes up with each cleared line (`grid_manager.cleared_row_or_column`), and by
  `booster_multiplier` with the booster, never past `GameConfig.max_score_multiplier` (10). It resets in
  `main.gd` on `timer_manager.combo_expired`; the HUD only displays it. Each cleared line restarts the combo timer at
  `TimerManager.combo_reset_time` (15 s). The combo timer is counted by hand in
  `timer_manager._process`, not with a `Timer` node, so it can run slower. It pauses with the tree.
- **Line clears** free their cells immediately, then animate the tiles in a wave from where the piece landed.
- **Broken blocks fly into the score** (`scenes/effects/score_fragments.gd`): each broken tile (line clears and
  power-ups) bursts into a few fragments that fall for a moment, then curve up and converge into the score number,
  shrinking and brightening on the way. `grid_manager.score_target` (set by `main.gd` to
  `top_tray.get_score_global_center`) says where to fly; without it, the old falling burst (`block_burst.gd`) is used.
  That burst is still used for the soft puff when a piece is placed.
- **The score number counts up as the fragments land.** `grid_manager.score` (the real score: saving, unlocks, game
  over) changes right away, but the HUD waits: when a block breaks, the grid sends `fragments_launched(count)` before
  the score changes, then `fragment_arrived` for each fragment that reaches the score. `top_tray` shows a share of
  the waiting points on each arrival (all of them with the last), with a small punch at most every 90ms. If nothing
  lands for 2.5s it catches up on its own (`_catch_up_later`), so the number can't get stuck.
- **Pieces that don't fit** are dimmed after every move (`main._update_playable`), including a prism while the
  board has no blocks (`grid_manager.can_place_powerup_anywhere`).
- **The multiplier number catches fire** (`combo_badge.gd`, drawn in code) from `GameConfig.fire_multiplier` (x5):
  one stylized flame behind the "x5" (a round base, a tall tongue leaning right and two small side flicks, in three
  layers: orange, light orange and a yellow core), gently flickering and a bit bigger up to x10. While it burns, the
  number is a cool white (`FIRE_TEXT`) with a thick dark outline so it stands out from the fire. It's drawn on top of
  the dark disc but under the timer ring and the number, and stays inside the ring's inner edge, so the combo timer
  is never covered.
- **A crown next to the best score** (`scenes/ui/crown_icon.gd`, drawn in code): gold, three points with balls on
  top and gems on the band, sized from the best label's font (`top_tray.BEST_FONT_SIZE`). It sits left of the label
  in an `HBoxContainer` in the score `VBoxContainer`, so the pair stays centred under the score.

### Saving
- **Settings** (`user://settings.cfg`) are saved as soon as an option changes. They also hold `best_score` and
  `backpack_slots`, the number of unlocked backpack slots (permanent unlocks).
- **The run** (`user://run.json`) holds the board, the tray slots (shape or power-up by name, plus color), the backpack
  contents, score, multiplier and combo time left. It's saved after every drop, on pause, when going to the menu, and
  when the app goes to the background. It's cleared on game over or New game. Bump `SaveGame.VERSION` when the format
  changes, and older saves are then ignored.

### Backpack
- There are 5 slots (`Backpack.SLOT_COUNT`), and slot 1 is always open. The rest unlock at
  `GameConfig.backpack_unlock_scores = [0, 35000, 100000, 250000, 500000]`. Reaching a score during a game unlocks
  that slot for good (`Settings.backpack_slots`, saved as `backpack_slots_v2`). Past best scores don't count, so
  new players always start with 1 open slot.
- While a tray power-up is dragged, free slots glow. Dropping on one (with some margin around it) stores the power-up
  and uses up the tray piece, like placing it. A stored power-up is dragged onto the grid the same way as from the
  tray, and returns to its slot if dropped elsewhere. A power-up dropped on a slot holding the same one merges into
  its mega version there (see "Mega power-ups").
- **Trash can** (`scenes/ui/trash_can.gd`) after the last slot: it glows while any power-up is dragged (from the tray
  or a slot) and opens its lid when one is over it. Dropping there throws the power-up away for its
  `"trash_score"` in `ShapeDefinitions.POWERUPS` (bomb 100, laser 150, prism and booster 200, hourglass 400, 3× that
  for the mega ones, not multiplied), via `grid_manager.add_score`. Its drop area is tighter than the slots' and checked first, because
  slot 5's margin reaches into it.

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

### Localization
- **Strings live in `localization/strings.csv`** (columns `keys,en,pt_BR,es`). Godot imports it into
  `strings.<locale>.translation` files, which are registered in `project.godot` under `[internationalization]`.
  The fallback is `en`.
- **Never put visible text in code; use a key.** A Control whose `text` is a key translates itself and updates
  when the language changes. Text built from values uses `tr("KEY") % value` and is rebuilt in
  `_notification(NOTIFICATION_TRANSLATION_CHANGED)` (see `top_tray.gd`, `main_menu.gd`, `options_panel.gd`,
  `game_over_panel.gd`).
- **Things that aren't translated:** turn auto-translation off (`auto_translate_mode = DISABLED`) on labels showing
  text that must stay as it is (music titles) or that's already translated. The game's name "Blockpack" isn't
  translated either.
- **Choosing the language:** `Settings.language` is `""` (automatic, which follows `OS.get_locale()`) or a code from
  `Settings.LANGUAGES`. `Settings.set_language()` applies it right away and saves it. Godot matches the closest
  translation, so `pt_PT` gets `pt_BR`, any `es_*` gets `es`, and the rest get English. In Options, the Language
  button cycles Automatic → English → Português (Brasil) → Español.
- **Adding a language:** add a column to the CSV, register its `.translation` file in `project.godot`, and add it
  to `Settings.LANGUAGES` with its own name. Scripts beyond Latin, Cyrillic and Greek need a fallback font (Noto) in
  a theme. Check the widths: Portuguese and Spanish run about 30% longer than English.

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
- **Power-up and trash can sprites** (`assets/powerups/*.png`, plus `scenes/powerups/bomb_body.png`) are made by
  `tools/powerup_sprites.py` in the same art style as the backpack: it imports `backpack_icons.py` and uses its
  pillow shading (`lit_shade`), the same outline colour and thickness, cast shadows and a ground shadow. Run
  `python3 tools/powerup_sprites.py assets/powerups` (and `... scenes/powerups bomb_body` for the bomb), or
  `--preview <dir>` for all of them side by side. Layout facts the code relies on: the bomb body is centred at
  (99, 121) of its 198px texture with a 98px diameter (the fuse path in `powerup_bomb.gd` starts at its cap), and the
  trash lid's hinge is at (0.86, 0.5) of its texture, placed at (0.86, 0.3) of the bin's (`trash_can.gd`).
- **The app icon** is `assets/icon/icon.png` (`config/icon` in `project.godot`), drawn by `tools/app_icon.py`: variant
  `j2`, a 4x4 board with a cyan L piece dropping into its gap and the b5 backpack releasing a bomb, a star and the
  diamond. It reuses `backpack_icons.py` (imported) and draws the blocks the same way as `block_visual.gd`. The script
  keeps the other variants that were tried (`i1` to `i3`, `j1`). `--final` writes the 512px icon plus the Android
  adaptive foreground/background (432px); see the README's App icon section for where they go.
- **Scores are shown with `NumberFormat.compact()`**: full below 10,000, then 75.3K, 253K, 1.25M. Values are cut
  down, never rounded up.

## Plans for the future

### Piece randomizer
- **Difficulty curve:** spawn smaller pieces first, then bring in bigger ones as the game goes on. Possible measures
  of progress: score, pieces placed, or lines cleared. Weight each shape in `ShapeDefinitions.SHAPES` by its size
  (cell count) and shift the weights as progress grows, instead of the current uniform `get_random_shape_name()`.
- **Every batch of 3 tray pieces must be 3 different pieces** (no repeated shape in the same batch). Roll the batch
  as a whole in `bottom_tray`, not one slot at a time.
- The testing shortcut in `randomize_shape()` (always `square_3x3`) goes away as part of this.

### Skins (main menu)
- **A new "Skins" section in the main menu** for unlocking and picking cosmetic looks for:
  - **the board:** panel, border, empty cells and background;
  - **the top and bottom trays:** HUD discs, tray slots and the backpack bar;
  - **the pieces:** block colors and block style, e.g. glossy, flat, pixel or glass.
- **Locked skins** show a padlock and what unlocks them, the same pattern as the backpack slots. Unlocks are
  permanent and saved in `Settings`.
- **Still to decide with the owner:** how skins are unlocked (score milestones, lines cleared, games played,
  achievements, or a currency earned by playing) and how many skins each category starts with.
- **How it could be built:**
  - **Skin data:** today every color is a constant in `configs/palette.gd`. Each skin would become a set of those
    values (a Resource or a dictionary per skin), read through a `Skins` autoload instead of the constants.
  - **Who reads it:** `block_visual.gd`, `grid_manager._draw` (the board), `background.gd`, the tray slots
    (`randomized_block._draw`), the HUD discs and the backpack slots would read the current skin. They'd redraw
    when it changes (a `Skins.changed` signal).
  - **Block styles** beyond colors (pixel, glass) would be different draw paths in `block_visual.gd`, selected by
    the piece skin.
  - **Saving:** the selected skin per category and the unlocked skins go in `Settings` (`user://settings.cfg`), not
    in the run save.
  - **Menu screen:** a skins screen with 3 tabs (board, trays, pieces). Each skin is a small live preview, a few
    blocks on a mini board, so it reuses the real drawing code instead of image files.

### A better main menu logo
- **Today** the title is just "Blockpack" as yellow text (`UiStyle.label` in `main_menu.gd`) with a slow bob and tilt
  (`_animate_title`). The goal is a logo that looks like a game logo and has some life to it. **Not decided yet**;
  think it through with the owner before building.
- **Animation ideas:**
  - blocks falling from the top of the screen and landing to form the word, or into place around it;
  - the letters dropping in one by one with a bounce, then a short line-clear flash across the word;
  - a piece sliding into a gap in the word, like placing a piece on the board;
  - the backpack opening and power-ups (bomb, star, diamond) popping out;
  - after the intro, small idle touches, e.g. a shine sweeping across the letters every few seconds.
- **A first try that was rejected:** a static logo with an L piece made of blocks for the "L" and the backpack sprite
  for the "O" ("B L O CKPACK"). It's in git history (commit `c2c3c1e`, reverted in `44ec3eb`) if parts of it are
  useful, e.g. how it lined blocks and the backpack up on the text's baseline.
- **Keep in mind:** it should still read well at phone size, keep the same colors as the app icon (yellow letters,
  cyan L piece, brown backpack), and the intro shouldn't delay the menu buttons; they can be usable right away.

### Blocks worth more as the game goes on
- **Idea:** make every block increasingly valuable as a game progresses, so long runs feel rewarding and scores keep
  climbing. Today a block is always worth `GameConfig.points_per_block` (10), times the combo multiplier.
- **Ways to measure progress:** lines cleared in this game, pieces placed, time played, or score bands. Lines
  cleared ties the reward to what the player does.
- **Possible curves:**
  - steps (e.g. +5 points per block every 10 lines cleared);
  - a gentle linear or logarithmic growth, so late values don't explode;
  - "levels" with a short "Level up! Blocks now worth 20" banner, which also gives a moment of celebration.
- **Where it would go:** a `points_per_block_now()` helper (in `GameConfig` or `grid_manager`) used everywhere
  `GameConfig.points_per_block` is read today: line clears and `_destroy_cells` for power-ups in
  `grid_manager.gd`. The current value (or level) is saved with the run.
- **Show it:** the HUD could show the current block value or level (e.g. under the multiplier badge), so players see
  it grow.
- **Balance:** it combines with the combo multiplier and the planned difficulty curve (bigger pieces later). The
  backpack unlock scores (35K–500K) may need retuning once scores grow faster.

## Known leftovers
- `randomize_shape()` in `randomized_block.gd` has a testing shortcut that always returns `square_3x3`. Remove it to
  get normal piece variety.
- The `.import` files for the music aren't committed yet.
