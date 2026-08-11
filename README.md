# Riptide Themer

An unofficial macOS style patch for `/Applications/HumanLayer.app` (`com.humanlayer.riptide`). It injects [`rounded.css`](./rounded.css) into the app's `WKWebView` and reapplies the patch after login and HumanLayer updates.

## How it works

1. `wk-css-injector.m` builds an ad-hoc-signed dynamic library that installs the stylesheet at document start.
2. `patch-riptide-beta.sh` adds the injector and stylesheet paths to HumanLayer's `LSEnvironment`, then re-signs the app with library validation disabled.
3. `install-autopatch.sh` installs a per-user LaunchAgent that runs at login and when the HumanLayer bundle changes.

## Requirements

- macOS 13 or newer
- HumanLayer installed at `/Applications/HumanLayer.app`
- Xcode Command Line Tools
- A local code-signing identity set through `RIPTIDE_PATCHER_SIGNING_IDENTITY`

## Install

```sh
export RIPTIDE_PATCHER_SIGNING_IDENTITY="Apple Development: Your Name (TEAMID)"
./install-autopatch.sh
open /Applications/HumanLayer.app
```

Use `security find-identity -v -p codesigning` to list the signing identities available in your keychain. Use your own identity; never share or commit its private key.

The installer builds the injector and patcher app, patches HumanLayer, and registers `~/Library/LaunchAgents/com.riptide.rounded.autopatch.plist`. Keep the checkout in place after installation because the patcher runs scripts and reads CSS from that path.

## Change styles

Edit `rounded.css`, then quit and reopen HumanLayer. CSS-only changes do not require rebuilding or re-signing the app.

To preview changes without restarting HumanLayer, serve the repository and open the standalone theme fixture:

```sh
python3 -m http.server 4173
open http://localhost:4173/theme-preview.html
```

The editor uses the captured HumanLayer task page as its preview canvas. It loads the real `rounded.css`, provides an exact Original/Rounded A/B view, and includes live palette, radius, font, viewport, and custom CSS controls.

`humanlayer-task-reference.html` contains the production DOM and all four loaded production stylesheets inline, with application scripts removed. Its task names, workspace path, links, and identifiers are neutral mock data.

Before replacing the fixture, copy `scripts/private-replacements.example.tsv` to `scripts/private-replacements.tsv` and add one tab-separated source/replacement pair for each private value. The local replacements file is ignored by Git. Run `node scripts/sanitize-humanlayer-reference.mjs`, inspect the full diff, and confirm that only neutral mock data remains before committing the capture.

For native injector changes:

```sh
./build-local-injector.sh
./patch-riptide-beta.sh
```

## Remove

Unload and remove the LaunchAgent and patcher app, then reinstall the official HumanLayer app to restore its original bundle and signature.

## Security

This project is not supported by HumanLayer. It modifies and re-signs the installed app, injects a dynamic library, enables DYLD environment variables, and disables library validation. The per-user LaunchAgent runs code from this checkout at login and after app updates.

Review the exact revision before installation. Do not install untrusted forks or updates. Reinstall the official HumanLayer app to restore the original bundle and signature.

## License

MIT. See [`LICENSE`](./LICENSE).
