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

Custom CSS in the editor is temporary. Copy any rules that you want to keep into [`rounded.css`](./rounded.css) or a scoped preset in [`theme-presets.css`](./theme-presets.css).

## Understand the theme files

| File | Purpose |
| --- | --- |
| [`rounded.css`](./rounded.css) | The stylesheet injected into the installed HumanLayer app. Changes here are permanent after you restart the app. |
| [`theme-preview.html`](./theme-preview.html) | The editor controls, preset names, and preset token values. |
| [`theme-presets.css`](./theme-presets.css) | Preview-only component treatments for named presets. The installer does not inject this file. |
| [`current-riptide-dom-reference.md`](./current-riptide-dom-reference.md) | A compact map of stable Riptide selectors. |
| [`humanlayer-task-reference.html`](./humanlayer-task-reference.html) | The sanitized interface used by the preview. Do not hand-edit it to create a theme. |

The installed patch always reads `rounded.css`. If you design a preset in the editor and want to use it in the app, move its final tokens and component rules into `rounded.css`.

## Change the main design tokens

Edit the `CURRENT RIPTIDE APP COHESION — THEME TOKENS` section in `rounded.css`. These tokens control most of the interface:

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

After you save `rounded.css`, select **Reload rounded.css** in the editor. To see the result in HumanLayer, quit and reopen the app. CSS-only changes do not require a rebuild or a new signature.

## Add a preview preset

Use a lowercase kebab-case ID, such as `paper-blue`.

1. Add an `<option>` to `#theme-preset` in `theme-preview.html`.
2. Add a matching entry to `themePresets`. Define `colorScheme`, `transparentBorders`, all palette colors, `radius`, and `font`.
3. If the preset changes more than tokens, add rules to `theme-presets.css` under `html[data-rr-preset="paper-blue"]`.
4. Scope every preset-specific rule to that attribute. Unscoped rules can change other presets.
5. Test the preset at all three preview sizes and compare it with **Original**.

Token changes belong in `theme-preview.html`. Component changes, such as a filled active navigation row or a special button treatment, belong in `theme-presets.css`.

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

Read THEMING.md, rounded.css, theme-preview.html, theme-presets.css, and
current-riptide-dom-reference.md before editing.

Implement the preset in theme-preview.html. Add only the component-specific
rules that it needs to theme-presets.css, scoped under
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
- The installed version of the theme is present in `rounded.css`, not only in the preview-only preset file.

Inspect the final changes with:

```sh
git diff -- README.md THEMING.md rounded.css theme-preview.html theme-presets.css
git diff --check
```

## Recover from a bad theme

Use **Reset** in the editor to return to the selected preset. If an installed CSS change is broken, revert that change in `rounded.css`, then quit and reopen HumanLayer.

To remove the patch completely, follow the [Remove](./README.md#remove) instructions.
