# Pilp

Pick it. Paste it your way.

Pilp is an open-source macOS clipboard picker. It watches copied text and images, then opens a fast horizontal picker from a shortcut you choose.

> Pilp is under active development. The picker currently copies your selection back to the clipboard; press `Command-V` once more to paste it into the active app.

## What works

- Watches text, PNG, and TIFF clipboard changes while Pilp is running
- Opens a floating picker from a user-recorded global shortcut
- Shows five recent clips in a centered horizontal ribbon
- Moves through clips with the left and right arrow keys
- Copies the selected clip back to the clipboard with Return
- Copies captured text back as plain text, without rich formatting
- Previews copied images up to 20 MiB each
- Keeps newest clips first
- Moves a copied duplicate back to the front
- Ignores blank text and trims history to the latest 10 clips
- Stores history in memory only and clears it when the app quits

## Use Pilp

1. Open `Pilp.app`. A Pilp icon appears in the macOS menu bar.
2. Open Pilp Settings and record a global shortcut. Pilp does not take over a default shortcut on first launch.
3. Copy text or an image as usual with `Command-C`.
4. Press your Pilp shortcut from any app. You can also choose **Show Picker** from the menu bar icon.
5. Press `Left Arrow` or `Right Arrow` to choose a clip.
6. Press `Return` to copy the selected clip back to the clipboard, or `Escape` to close the picker.
7. Press `Command-V` in the destination app.

## Next

- Paste a selection directly into the active app
- Optionally preserve rich text instead of always using plain text
- Add a total memory limit for image history
- Add search and pinned clips after the core picker is validated

## Requirements

- macOS 15 or later
- Apple Silicon Mac for the initial prototype
- Swift 6.2 or later with a matching macOS SDK

## Build from source

Run the tests:

```sh
swift test
```

Build a local ad-hoc signed app bundle:

```sh
./scripts/build-app.sh
open dist/Pilp.app
```

The generated `dist/Pilp.app` is for local development. Public releases will require Developer ID signing and notarization.

## Privacy

Pilp does not use an account, network connection, telemetry, or persistent clipboard storage in the current prototype.

## License

[MIT](LICENSE)
