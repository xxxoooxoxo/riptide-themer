# Current Riptide DOM Reference

Derived from the current HumanLayer/Riptide app shell. This compact selector
map supports maintenance of `rounded.css` without
keeping a large generated HTML snapshot in the extension repo.

## Document

- `html[data-theme="nord-vscode"]`
- `body > #app`
- Main shell: `#app > .flex.flex-col.min-h-dvh.h-dvh.max-h-dvh.bg-background`
- Tauri drag strip: `.tauri-titlebar-drag-region`

## Primary Layout

- Root split group: `[data-slot="resizable-panel-group"][data-testid="_r_c_"]`
- Task tree panel: `[data-testid="task-tree-sidebar"]`
- Main panel: `[data-testid="main"]`
- Artifact/right panel: `[data-testid="sidebar"]`
- Resizer handles: `[data-slot="resizable-handle"]`

## Sidebar

- Sidebar shell: `[data-testid="task-tree-sidebar"] .bg-sidebar`
- Task rows: `[data-sidebar-task-id]`
- Session rows: `[data-sidebar-session-id]`
- Active session row: `[data-sidebar-session-id][data-active="true"]`
- Sidebar footer switches: `#sidebar-variant-switch`, `#sidebar-phase-labels-switch`

## Breadcrumb

- Breadcrumb nav: `nav[aria-label="breadcrumb"]`
- Editable breadcrumb buttons use small icon buttons with `aria-label`
- Host selector button: `button[aria-haspopup="dialog"]`

## Conversation

- Main card: `.Conversation-Card`
- Scroll container: `[data-conversation-container="true"]`
- Virtualized message row wrapper: `[data-index]`
- Message row: `[data-conversation-container="true"] .group[data-event-id]`
- Active/current row: `.group[class*="bg-accent"]`
- Thought row icon: `.lucide-brain`
- Assistant row icon: `.lucide-bot`
- Shell command row icon: `.lucide-terminal`
- File/read row icon: `.lucide-file-text`
- Write row icon: `.lucide-file-pen`
- Rendered markdown: `.prose-terminal`

## Composer

- Composer wrapper: `div[class*="shrink-0"][class*="pt-4"]:has(.tiptap.ProseMirror)`
- Composer card: `div.border.rounded-lg.relative:has(.tiptap.ProseMirror)`
- Editor: `.tiptap.ProseMirror`
- Send button: button containing `.lucide-send`

## Artifacts Panel

- Panel card: `[data-testid="sidebar"] [data-slot="card"]`
- Tabs: `[data-testid="sidebar"] [role="tablist"]`, `[data-testid="sidebar"] button[role="tab"]`
- Artifact list buttons: `[data-testid="sidebar"] [role="tabpanel"] button`
- Artifact section headings: `[data-testid="sidebar"] section h3`

## Footer

- Footer: `footer`
- Left version area: `footer #left`
- Shortcut area: `footer #center`
- Right actions: `footer #right`
