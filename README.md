# Riptide Themer

An unofficial macOS style patch for both current HumanLayer desktop apps:

- `/Applications/HumanLayer.app` (`com.humanlayer.riptide`)
- `/Applications/HumanLayerElectron.app` (`com.humanlayer.electron`)

It injects [`rounded.css`](./rounded.css) into the native app's `WKWebView` or installs it as an Electron renderer asset, then reapplies the patch after login and HumanLayer updates.

## How it works

1. `wk-css-injector.m` builds an ad-hoc-signed dynamic library that installs the stylesheet at document start.
2. `patch-riptide-beta.sh` adds the injector and stylesheet paths to native HumanLayer's `LSEnvironment`, then re-signs the app with library validation disabled.
3. `patch-humanlayer-electron.sh` copies the base stylesheet and selected preset into Electron's renderer, activates the preset on the document, and re-signs the app.
4. `install-autopatch.sh` installs a per-user LaunchAgent that runs both patchers at login and when either HumanLayer bundle changes.

## Requirements

- macOS 13 or newer
- At least one supported HumanLayer app installed in `/Applications`
- Xcode Command Line Tools
- A local code-signing identity set through `RIPTIDE_PATCHER_SIGNING_IDENTITY`

## Install

```sh
export RIPTIDE_PATCHER_SIGNING_IDENTITY="Apple Development: Your Name (TEAMID)"
./install-autopatch.sh
open /Applications/HumanLayerElectron.app
```

Use `security find-identity -v -p codesigning` to list the signing identities available in your keychain. Use your own identity; never share or commit its private key.

The installer builds the injector and patcher app, patches every supported HumanLayer app it finds, and registers `~/Library/LaunchAgents/com.riptide.rounded.autopatch.plist`. Keep the checkout in place after installation because the patcher runs scripts and reads CSS from that path.

## Change styles

HumanLayer Electron defaults to the `lets-get-nauti` preset and persists the selection at `~/Library/Application Support/Riptide Rounded Patcher/theme-preset`. Override it for one patch with `RIPTIDE_THEME_PRESET=<name>`; the matching file must exist in `presets/`.

For native HumanLayer, edit `rounded.css`, then quit and reopen the app. For HumanLayer Electron, run `./patch-humanlayer-electron.sh` after a base or preset CSS edit so the renderer copies and app signature are refreshed.

See the [theming guide](./THEMING.md) for the token map, preset workflow, selector guidance, and prompts for creating a theme with AI.

To preview changes without restarting HumanLayer, serve the repository and open the standalone theme fixture:

```sh
python3 -m http.server 4173
open http://localhost:4173/theme-preview.html
```

The editor uses the captured HumanLayer task page as its preview canvas. It loads the real `rounded.css`, provides an exact Original/Rounded A/B view, and includes Vercel Dark and Let's Get Nauti token presets plus live palette, radius, font, viewport, and custom CSS controls. Let's Get Nauti layers `#F9F7F4`, `#FDFBFC`, and `#F6F5F1` with Inter typography, while Nautilus Blue (`#06B2DD`) is reserved for primary actions and focus. Pocket's component-only dark code and toast tokens are not presented as a full dark preset.

`humanlayer-task-reference.html` contains the production DOM and all four loaded production stylesheets inline, with application scripts removed. Its task names, workspace path, links, and identifiers are neutral mock data.

Before replacing the fixture, copy `scripts/private-replacements.example.tsv` to `scripts/private-replacements.tsv` and add one tab-separated source/replacement pair for each private value. The local replacements file is ignored by Git. Run `node scripts/sanitize-humanlayer-reference.mjs`, inspect the full diff, and confirm that only neutral mock data remains before committing the capture.

For native injector changes:

```sh
./build-local-injector.sh
./patch-riptide-beta.sh
```

To patch only the Electron app (no injector build is needed):

```sh
./patch-humanlayer-electron.sh
```

## Remove

Unload and remove the LaunchAgent and patcher app, then reinstall the official HumanLayer app or apps to restore their original bundles and signatures.

## Security

This project is not supported by HumanLayer. It modifies and re-signs installed app bundles. The native patch injects a dynamic library, enables DYLD environment variables, and disables library validation; the Electron patch modifies renderer assets. The per-user LaunchAgent runs code from this checkout at login and after app updates.

Review the exact revision before installation. Do not install untrusted forks or updates. Reinstall the official HumanLayer app to restore the original bundle and signature.

## License

MIT. See [`LICENSE`](./LICENSE).
