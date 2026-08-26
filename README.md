# Pilp

Pick it. Paste it your way.

Pilp is an open-source macOS menu bar clipboard picker. It watches copied text and images, then lets you choose a recent clip from a compact horizontal deck.

> Pilp is under active development. The picker currently copies your selection back to the clipboard; press `Command-V` once more to paste it into the active app.

## What works

- Watches text, PNG, and TIFF clipboard changes while Pilp is running
- Shows one selected clip at a time in a menu bar deck
- Moves through clips with the left and right arrow keys
- Copies the selected clip back to the clipboard with Return
- Previews copied images up to 20 MiB each
- Keeps newest clips first
- Moves a copied duplicate back to the front
- Ignores blank text and trims history to the latest 10 clips
- Stores history in memory only and clears it when the app quits

## Use Pilp

1. Open `Pilp.app`. A Pilp icon appears in the macOS menu bar.
2. Copy text or an image as usual with `Command-C`.
3. Click the Pilp menu bar icon.
4. Press `Left Arrow` or `Right Arrow` to choose a clip.
5. Press `Return` to copy the selected clip back to the clipboard.
6. Return to your app and press `Command-V`.

## Next

- Open the picker with a global shortcut
- Let users customize the picker shortcut
- Paste a selection directly into the active app
- Paste rich text as plain text
- Add a total memory limit for image history

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
