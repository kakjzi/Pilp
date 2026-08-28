# Pilp

Pick it. Paste it your way.

Pilp is an open-source macOS clipboard picker. It watches copied text and images, then opens a fast horizontal picker from a shortcut you choose.

> Pilp is under active development. The picker currently copies your selection back to the clipboard; press `Command-V` once more to paste it into the active app.

## Distribution

Pilp supports macOS only. Official builds are published exclusively through [GitHub Releases](https://github.com/kakjzi/Pilp/releases). Pilp is not distributed through the Mac App Store, and Windows or Linux versions are not planned.

Early Alpha builds are ad-hoc signed and not notarized while the project is being validated. macOS will warn before opening one of these builds. Only download Pilp from this repository.

## What works

- Watches text, PNG, and TIFF clipboard changes while Pilp is running
- Opens a floating picker from a user-recorded global shortcut
- Opens a short setup guide on first launch
- Shows five recent clips in a movable horizontal ribbon near the bottom of the active screen
- Shows the source app and capture time for each clip
- Moves through clips with the left and right arrow keys
- Copies the selected clip back to the clipboard with Return
- Copies captured text back as plain text, without rich formatting
- Previews copied images up to 20 MiB each
- Keeps total in-memory image history under 80 MiB by removing the oldest images first
- Keeps newest clips first
- Moves a copied duplicate back to the front
- Ignores blank text and trims history to the latest 10 clips
- Stores history in memory only and clears it when the app quits
- Checks GitHub Releases for updates manually or automatically with Sparkle
- Can download verified updates in the background and install them through the standard macOS update flow

## Use Pilp

1. Open `Pilp.app`. The first-launch guide appears and a Pilp icon is added to the macOS menu bar.
2. Record a global shortcut in the guide. Pilp does not take over a default shortcut on first launch.
3. In **Updates**, choose whether Pilp should check for and download new versions automatically.
4. Copy text or an image as usual with `Command-C`.
5. Press your Pilp shortcut from any app. You can also choose **Show Picker** from the menu bar icon.
6. Press `Left Arrow` or `Right Arrow` to choose a clip.
7. Press `Return` to copy the selected clip back to the clipboard, or `Escape` to close the picker.
8. Press `Command-V` in the destination app.

## Install an unsigned Alpha

1. Download the ZIP marked **Pre-release** from [GitHub Releases](https://github.com/kakjzi/Pilp/releases).
2. Unzip it and move `Pilp.app` to the Applications folder.
3. Try to open Pilp once. macOS will block it because the Alpha is not registered with Apple.
4. Open **System Settings → Privacy & Security**, scroll to **Security**, then choose **Open Anyway** for Pilp. Apple documents this exception flow in [Open a Mac app from an unknown developer](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac/26).

Unsigned Alpha builds are excluded from the Sparkle update feed. Install the first future signed release manually once; automatic updates can continue from signed releases afterward.

## Next

- Paste a selection directly into the active app
- Optionally preserve rich text instead of always using plain text
- Add search and pinned clips after the core picker is validated

## Requirements

- macOS 15 or later
- Apple Silicon Mac for the initial prototype
- Swift 6.2 or later with a matching macOS SDK

## Build from source

Run the tests:

```sh
swift test --disable-keychain
```

Build a local ad-hoc signed app bundle:

```sh
./scripts/build-app.sh
open dist/Pilp.app
```

The generated `dist/Pilp.app` is for local development. Official GitHub Releases require Developer ID signing and notarization so the directly downloaded app can pass the standard macOS security checks.

The build script disables SwiftPM Keychain lookup because Pilp's package dependencies are public. This avoids unrelated `github.com` password prompts during local builds; Sparkle's private release-signing key remains in the maintainer's Keychain.

Package an ad-hoc signed, unnotarized Alpha without changing `appcast.xml`:

```sh
./scripts/package-alpha.sh 0.1.0 1
```

The command creates `dist/releases/Pilp-0.1.0-alpha.1.zip` and its SHA-256 checksum. Publish both files under a GitHub prerelease tag such as `v0.1.0-alpha.1`.

## Package a GitHub Release

Pilp uses Sparkle 2.9.4 and the repository-root `appcast.xml` as its update feed. The private EdDSA signing key stays in the maintainer's macOS Keychain under the account `com.kakjzi.Pilp`; only the public key is committed to the app's `Info.plist`.

GitHub Release packaging intentionally stops unless a Developer ID Application identity and a `notarytool` Keychain profile are available. Create a signed, notarized ZIP and update the appcast:

```sh
PILP_CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
PILP_NOTARY_PROFILE="pilp-notary" \
./scripts/package-release.sh 0.2.0 2
```

The script signs Sparkle's nested helpers from the inside out, enables Hardened Runtime and a secure timestamp, submits a temporary ZIP to Apple's notary service, staples the accepted ticket to `Pilp.app`, then creates the final archive. Upload `dist/releases/Pilp-0.2.0.zip` to the matching GitHub Release tag (`v0.2.0`) before publishing the updated `appcast.xml`. Every release must increase `CFBundleVersion`; Sparkle compares that build number to decide whether an update is newer.

Versions released before Sparkle was embedded cannot update themselves and must be replaced manually once. Versions released with this integration can use **Check Now** or the automatic update settings afterward.

## Privacy

Pilp does not use an account, telemetry, or persistent clipboard storage. Clipboard contents stay on the Mac. When update checking is enabled—or when **Check Now** is pressed—Pilp contacts the public GitHub-hosted update feed and downloads release files only when an update is available.

## License

[MIT](LICENSE)
