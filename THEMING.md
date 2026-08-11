# Theming Riptide

Use the theme editor to choose the broad look, then use CSS for the details. You can make a theme by hand or ask an AI coding agent to edit the same files.

## Open the theme editor

From this repository, start a local server:

```sh
python3 -m http.server 4173
open http://localhost:4173/theme-preview.html
```

The editor uses a sanitized copy of the real HumanLayer interface. It does not connect to your account or change the installed app.

Start with these controls:

1. Select a preset that is close to the result you want.
2. Set the background, surface, text, border, and primary colors.
3. Set the radius and content font.
4. Check desktop, tablet, and mobile sizes.
5. Switch between **Original** and **Rounded** to confirm that each change is intentional.
6. Use **Custom CSS** for a focused experiment.

Custom CSS in the editor is temporary. Copy shared rules into [`rounded.css`](./rounded.css) or preset-specific rules into the matching file under [`presets/`](./presets).

## Understand the theme files

| File | Purpose |
| --- | --- |
| [`rounded.css`](./rounded.css) | Shared styling injected before the selected preset. |
| [`theme-preview.html`](./theme-preview.html) | The editor controls, preset names, and preset token values. |
| [`presets/`](./presets) | Installable preset tokens and component treatments. The injector loads the selected file after `rounded.css`. |
| [`theme-presets.css`](./theme-presets.css) | Preview bundle that imports the installable preset files. |
| [`current-riptide-dom-reference.md`](./current-riptide-dom-reference.md) | A compact map of stable Riptide selectors. |
| [`humanlayer-task-reference.html`](./humanlayer-task-reference.html) | The sanitized interface used by the preview. Do not hand-edit it to create a theme. |

The installed patch reads `rounded.css`, then `presets/<selected-preset>.css`. Run `./set-theme.sh <preset>` to change the selection. The choice is stored in `~/Library/Application Support/Riptide Rounded Patcher/theme-preset` and survives app updates.

## Change the main design tokens

Edit the root selector in the active preset file. These tokens control most of the interface:

| Token | Controls |
| --- | --- |
| `--rr-bg` | App canvas and terminal background |
| `--rr-bg-elevated` | Elevated headers and panels |
| `--rr-surface-1` | Cards and the sidebar |
| `--rr-surface-2` | Inputs, code blocks, and raised controls |
| `--rr-surface-3` | Stronger nested surfaces |
| `--rr-border-base` | Source color used to make borders |
| `--rr-text` | Main text |
| `--rr-text-muted` | Secondary text |
| `--rr-text-faint` | Placeholders and low-emphasis details |
| `--rr-cyan` | Primary action and focus color |
| `--rr-blue` | Secondary accent |
| `--rr-green` | Success |
| `--rr-yellow` | Warning |
| `--rr-red` | Error and destructive states |
| `--rr-font-content` | Prose and interface font stack |

Keep success, warning, and error colors distinct. A brand color should not replace status colors.

After you save a stylesheet, select **Reload rounded.css** in the editor. To see the result in HumanLayer, quit and reopen the app. CSS-only changes do not require a rebuild or a new signature.

## Add a preset

Use a lowercase kebab-case ID, such as `paper-blue`.

1. Create `presets/paper-blue.css` and scope every rule under `html[data-rr-preset="paper-blue"]`.
2. Import that file from `theme-presets.css` so the editor can load it.
3. Add an `<option>` to `#theme-preset` in `theme-preview.html`.
4. Add a matching entry to `themePresets`. Define `colorScheme`, `transparentBorders`, all palette colors, `radius`, and `font`.
5. Test the preset at all three preview sizes and compare it with **Original**.
6. Run `./set-theme.sh paper-blue`, then reopen HumanLayer.

Keep the preset's real token defaults and component rules together in `presets/paper-blue.css`. Mirror its editable token values in `theme-preview.html` so the controls open with the same palette.

## Add a component rule

Prefer a stable semantic hook from `current-riptide-dom-reference.md`:

```css
html[data-theme="nord-vscode"] [data-testid="sidebar"] [role="tablist"] {
  border-radius: 10px !important;
}
```

Use this order of preference:

1. `data-testid`, `data-slot`, or another named data attribute
2. ARIA role or label
3. A short, stable class selector
4. A structural selector only when no semantic hook exists

Avoid generated IDs and long Tailwind class chains. Riptide can change them between releases. Keep each rule narrow, and add `!important` only when it must override an inline or application rule.

## Use AI to make a theme

AI works best when you give it a visual goal, a small file scope, and a clear check. Include a screenshot, a brand page, or exact colors when you have them.

You can paste this prompt into a coding agent from the repository root:

```text
Create a new Riptide preview preset named "Paper Blue" with the ID "paper-blue".

Visual direction:
- calm light theme
- paper-like warm background
- white cards
- blue only for primary actions and focus
- green, yellow, and red remain semantic status colors
- 10px surface radius and Inter for content

Read THEMING.md, rounded.css, theme-preview.html, theme-presets.css, presets/, and
current-riptide-dom-reference.md before editing.

Implement the preset in theme-preview.html and presets/paper-blue.css. Import
the preset from theme-presets.css. Scope every preset rule under
html[data-rr-preset="paper-blue"]. Do not edit the native patcher, captured HTML,
or private environment files. Do not invent selectors when the DOM reference
contains a stable hook. Do not run a build. Check the diff and run the available
typecheck if this repository has one.
```

For a smaller correction, give AI the element and the current problem:

```text
Refine only the active sidebar row in the "paper-blue" preset. It should use a
quiet neutral fill, keep readable text, and reserve blue for keyboard focus.
Use the existing data attributes. Do not change the global tokens or other
presets. Explain which selector you used.
```

If you want AI to generate a quick experiment, ask for a small CSS block and paste it into **Custom CSS**. Once it looks correct, ask the agent to place it in the correct scoped file.

## Review AI changes

Before you keep an AI-generated theme, confirm that:

- Only the intended theme files changed.
- No private paths, account data, signing identities, or environment values entered the diff.
- Preset-only rules start with the correct `data-rr-preset` selector.
- Text and controls remain readable in default, hover, active, focus, disabled, success, warning, and error states.
- The layout still works at desktop, tablet, and mobile sizes.
- **Original** still matches the captured interface.
- The installable theme is present under `presets/`, not only in preview JavaScript.

Inspect the final changes with:

```sh
git diff -- README.md THEMING.md rounded.css theme-preview.html theme-presets.css presets/
git diff --check
```

## Recover from a bad theme

Use **Reset** in the editor to return to the selected preset. If an installed preset is broken, switch back with `./set-theme.sh vercel-dark`, then reopen HumanLayer.

To remove the patch completely, follow the [Remove](./README.md#remove) instructions.
