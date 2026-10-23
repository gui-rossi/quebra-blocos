# Blockpack

A mobile block puzzle game made with **Godot 4.7**: drag pieces from the tray onto a 10×12 board, clear full rows
and columns, chain clears for a bigger score multiplier, and use power-ups (bomb, laser, prism, booster, hourglass)
or keep them in the backpack for later. It's in English, Brazilian Portuguese and Spanish, and has a public-domain
classical soundtrack.

## Running it

1. Install [Godot 4.7](https://godotengine.org/download) (the standard build, not .NET).
2. Open the project: **Import** in the Project Manager, then pick this folder's `project.godot`.
3. Press **F5** (Run Project). It opens on the main menu. The mouse works as a finger (touch is emulated).

The first time you open it, Godot imports the assets and creates `.import` and `.translation` files next to them.
Commit those.

## Building an executable

### 1. Install the export templates (once)
1. Go to **Editor → Manage Export Templates…**.
2. Click **Download and Install**.

The templates must match the editor version exactly (4.7). The download is about 1 GB.

### 2a. Windows `.exe` (quickest way to test)
1. Go to **Project → Export…**, then **Add… → Windows Desktop**.
2. Optional: check **Embed PCK** under Binary Format. You then get a single `.exe` instead of an `.exe` plus a
   `.pck`.
3. Click **Export Project…**, choose `build/` and a name like `blockpack.exe`.
4. Leave **Export With Debug** on while testing, and turn it off for a final build.

The game opens as a 720×1280 window, with touch emulated by the mouse.

### 2b. Android `.apk` (the real target)
You need extra setup the first time:
1. Install **OpenJDK 17** and the **Android SDK**. Android Studio installs the SDK, or you can use just the
   command-line tools.
2. In **Editor → Editor Settings → Export → Android**, set **Java SDK Path** and **Android SDK Path**.
3. Godot creates a debug keystore automatically, which is enough for testing.
4. Go to **Project → Export… → Add… → Android**. Set **Package → Unique Name** (e.g. `com.guirossi.blockpack`)
   and a version.
5. Click **Export Project…** to get `build/blockpack.apk`.

To install it on your phone, either copy the APK over, or enable USB debugging on the phone, plug it in, and use the
editor's one-click deploy button (the Android icon at the top right). That button builds the game and starts it
straight on the phone.

### For the Play Store
- You need a **release keystore**. Keep it safe: every future update must be signed with the same one.
- Upload an **AAB** instead of an APK: set **Export Format** to **Export AAB**, which requires **Use Gradle Build**.
- The store listing (title, description, screenshots) is localized separately in the Play Console.

### Building from the command line
Once a preset exists (it's saved in `export_presets.cfg`, which is safe to commit because passwords are kept in
`.godot/`):

```
godot --headless --export-release "Windows Desktop" build/blockpack.exe
godot --headless --export-release "Android" build/blockpack.apk
```

Builds go in `build/`, which is ignored by git. Never commit the `.exe`, `.apk` or `.aab` files.

## App icon

The icon is original art in `assets/icon/`: a board with a cyan L piece dropping into its gap and the game's backpack
releasing power-ups (a bomb, a star and the diamond). It's drawn by `tools/app_icon.py`, variant `j2`. Rebuild it with
`python3 tools/app_icon.py --final assets/icon j2` (takes a few minutes, pure Python).

| File | Size | Used for |
|---|---|---|
| `icon.png` | 512×512 | The project icon (`project.godot`), the Windows/desktop icon, and the **Play Store icon upload** |
| `icon_foreground.png` | 432×432 | Android **adaptive icon foreground** (the artwork, shrunk to stay inside the launcher's mask) |
| `icon_background.png` | 432×432 | Android **adaptive icon background** (the game's gradient) |

In **Project → Export… → Android → Launcher Icons**, set Main 192×192 to `icon.png`, Adaptive Foreground 432×432 to
`icon_foreground.png` and Adaptive Background 432×432 to `icon_background.png`. For the `.exe` icon on Windows, Godot
needs an `.ico` file and rcedit (Editor Settings → Export → Windows); you can convert `icon.png` to `.ico` with any
image tool.

## Play Store listing

Text ready to paste into the Play Console when the game is released. Google Play has no keyword field: search uses
the **title, short description and full description** (and reviews), so the search words below are written into the
descriptions naturally. Don't paste a bare list of keywords or other games' names: Google's metadata policy treats
that as keyword stuffing and can reject the listing.

### Title (max 30 characters)
- **Blockpack: Block Puzzle** (23). The game itself is just "Blockpack"; the subtitle is only for the store, so
  searches for "block puzzle" find it.

### Short description (max 80 characters)
- English: `Clear lines, chain combos and save power-ups in your backpack!` (62)
- Português (BR): `Limpe linhas, faça combos e guarde power-ups na sua mochila!` (60)
- Español: `¡Limpia líneas, encadena combos y guarda potenciadores en tu mochila!` (69)

### Full description (English)

> **Blockpack** is a relaxing yet challenging **block puzzle**. Drag colorful blocks onto the board, fill rows and
> columns to clear them, and chain clears to grow your **combo multiplier** for huge scores.
>
> **Power-ups** make every game different: blow up blocks with the **bomb**, sweep a row and column with the
> **laser**, clear a whole color with the **prism**, boost your multiplier, or slow down time with the rare
> **hourglass**. Not the right moment? Keep it in your **backpack** and use it when you need it. Reach higher scores
> to unlock more backpack slots for good.
>
> **Features**
> - Classic **block puzzle** gameplay: place pieces, clear lines, beat your best score
> - **Combos and multipliers** that reward clearing lines one after another
> - 5 **power-ups** and a **backpack** to save them for later
> - Unlock up to 5 backpack slots as your scores grow
> - Relaxing **classical music** and satisfying effects
> - Play **offline**, no internet needed
> - In English, Portuguese and Spanish
>
> A simple, **free puzzle game** to train your brain, a few minutes at a time. How high can you score?

Translate it for the Portuguese and Spanish listings with the same structure, using the search words below.

### Search words to work into the descriptions

| English | Português (BR) | Español |
|---|---|---|
| block puzzle | quebra-cabeça de blocos | rompecabezas de bloques |
| block puzzle game | jogo de blocos | juego de bloques |
| blocks | blocos | bloques |
| puzzle game | jogo de quebra-cabeça | juego de puzzle |
| brain game | jogo de raciocínio | juego de lógica |
| logic puzzle | quebra-cabeça de lógica | puzzle de lógica |
| line clear / clear lines | limpar linhas | limpiar líneas |
| combo | combo | combo |
| power-ups | power-ups / poderes | potenciadores |
| grid puzzle | quebra-cabeça em grade | puzzle en cuadrícula |
| relaxing game | jogo relaxante | juego relajante |
| offline game | jogo offline | juego sin conexión |
| free game | jogo grátis | juego gratis |
| casual game | jogo casual | juego casual |
| classic puzzle | quebra-cabeça clássico | puzzle clásico |
| high score | recorde | récord |
| backpack | mochila | mochila |

**Category:** Puzzle. **Tags** (picked in the Play Console): Block, Puzzle, Casual, Offline, Single player.

## More

- `CLAUDE.md`: how the project is organized, architecture decisions and plans for the future.
- `assets/music/CREDITS.md`: the source and license of every music track (all CC0 or public domain recordings).
