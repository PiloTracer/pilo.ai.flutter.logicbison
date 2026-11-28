# Desktop UI and UX craft

**Status:** Approved 2026-11-27  
**Needs:** Nothing

## Goal

Improve the framework’s desktop design guidance using the uncommitted page refresh in `/mnt/work/Projects/pilo.ai.soc.logicbison.app`. Teach models to pick a layout that supports the user’s task, preserve the interaction flow and verify the result visually and behaviorally.

## Evidence and decisions

Read the reference app’s shell, masthead, inventory, settings, editor, and run detail changes, along with the review notes. Inspected representative light and dark captures of Overview, the editor, History detail and Administration.

| Evidence from the reference | Framework change |
|---|---|
| Overview, editing, History and settings emphasize different content inside a shared shell | [Desktop surfaces](../resources/desktop-surfaces.md) maps screen types to content, actions and context. A masthead supports the dominant content chosen in the SPEC |
| The editor uses plan, active configuration and summary while preserving staged review | Guidance on applying visual references to existing data, actions and review steps |
| The neutral rail, canvas and card tones establish boundaries. A transparent Material restores switch feedback | Examples for theme layers, selection and ink in [Desktop surface recipes](../resources/desktop-surface-recipes.md) |
| Table columns need more room at 200% text and settings controls wrap when their sidebar crowds the form | [Desktop standard §5](../standards/20261123-DESKTOP_STANDARD.md#5-layout-for-a-resizable-window) and [FLS-13](../concepts/ui-craft/prompt.md) check the space available to the active surface and actual reachability |
| Run detail uses a record ID to scope revealed files | [UI craft §12](../standards/20260802-UI_CRAFT_STANDARD.md#12-desktop-surfaces) applies the same ownership to transient state and late results |
| In-progress report actions distinguish opening saved output from replacing it and can use the current record’s context | The design guide carries that distinction into saved-output flows and asks agents to name the replacement consequence |

The reference’s secondary accent links and reduced display title informed review checks. The recipes use their own sample palette and fixture data. Existing agents discover the guide through SPEC authoring, scaffolding, implementation, visual review and verification.

## Verification

Rechecked all ten published recipe blocks and the visual-review helper byte-for-byte against an isolated app using Flutter 3.50.1 and `material_ui` 1.11.1. Analysis, formatting, the fix dry run and the hygiene scan passed. The hygiene scan reported zero findings. Eleven widget tests passed, including real-font accessibility checks in light and dark.

The review measured a 292 logical pixel gap between the short inventory and the Add controls in the draft, and a 2.27:1 contrast ratio for its rail subtitle. The revised layout keeps Add next to the inventory and removes the subtitle. At 1024×768 and 200% text, the test checks that dragging the table brings the Owner column into view. Reviewed the expanded light inventory, minimum-width dark inventory, wrapped settings and error recovery with real glyphs. Verified the render helper delivers the requested size, brightness and text scale to the screen.

The framework integrity and self-test suites passed. The reference worktree was accessed read-only. Its report-action changes continued during the review, so the latest presentation diff was checked again. Native desktop behavior and independent LLM output quality remain unverified.

## Next action

None.
