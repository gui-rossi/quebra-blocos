# Block Blast: Enhanced!

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
3. Click **Export Project…**, choose `build/` and a name like `block-blast-enhanced.exe`.
4. Leave **Export With Debug** on while testing, and turn it off for a final build.

The game opens as a 720×1280 window, with touch emulated by the mouse.

### 2b. Android `.apk` (the real target)
You need extra setup the first time:
1. Install **OpenJDK 17** and the **Android SDK**. Android Studio installs the SDK, or you can use just the
   command-line tools.
2. In **Editor → Editor Settings → Export → Android**, set **Java SDK Path** and **Android SDK Path**.
3. Godot creates a debug keystore automatically, which is enough for testing.
4. Go to **Project → Export… → Add… → Android**. Set **Package → Unique Name** (e.g. `com.guirossi.blockblastenhanced`)
   and a version.
5. Click **Export Project…** to get `build/block-blast-enhanced.apk`.

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
godot --headless --export-release "Windows Desktop" build/block-blast-enhanced.exe
godot --headless --export-release "Android" build/block-blast-enhanced.apk
```

Builds go in `build/`, which is ignored by git. Never commit the `.exe`, `.apk` or `.aab` files.

## More

- `CLAUDE.md`: how the project is organized, architecture decisions and plans for the future.
- `assets/music/CREDITS.md`: the source and license of every music track (all CC0 or public domain recordings).
