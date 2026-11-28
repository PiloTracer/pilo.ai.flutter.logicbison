# Design desktop surfaces around the task

Use this guide for a new desktop workspace or a redesign of an existing Flutter screen. Keep the product’s tokens, terminology and task sequence. The [UI craft standard](../standards/20260802-UI_CRAFT_STANDARD.md#12-desktop-surfaces) and [desktop standard](../standards/20261123-DESKTOP_STANDARD.md#5-layout-for-a-resizable-window) define the review criteria.

## Decide what the user needs first

For each affected screen, identify the user’s immediate task, the content they need to see first, the action that advances the task, and the information they need alongside it. Use the existing SPEC and UI design system to make these decisions. In a redesign, look at the current screen and trace the flow first, including what is saved, what must be reviewed, and what users can recover from. Carry those behaviors through the design.

| Surface | Give prominence to | Keep nearby |
|---|---|---|
| Overview | The metric or status that answers the first recurring question | The next action and recent activity that explain the status |
| Inventory | Search, matching count and identifiable records | Add next to the inventory, row actions with their records, distinct first-use and no-match messages |
| Editor or wizard | The current question or active edit | Steps or outline on the left if there is room, a summary for cross-checking, and the existing Review or Continue action |
| Detail or report | The selected record’s identity and result, or the report body if reading is the task | Relevant actions and copyable values. Group metadata, source text and supporting logs below or alongside the main content |
| Settings | The selected topic and its fields | Topic navigation and feedback beside the settings being changed. Let the topic controls wrap when they compete with the form |
| Readiness or recovery | The first unmet prerequisite and its consequence | The action that fixes it and an indication of what becomes available next |

A saved output can usually be opened independently of regenerating it. Label those actions separately, show what a replacement will overwrite, and keep the original inputs available. When context already identifies the target, carry it into the action so the user can review it in place.

A consistent shell lets people recognize where they are. Give each page a layout suited to its task. If a reference mockup offers a clearer grouping or stronger visual hierarchy, apply that treatment to the information and actions the product actually supports. Keep illustrative metrics in review fixtures and preserve deliberate review steps. The reference refresh used this approach to give the editor a plan, active edit and summary while preserving its staged review.

## Choose the pieces you need

| Decision | What to apply | Flutter example |
|---|---|---|
| Make section, workspace and content boundaries legible | Use related neutral tones for the frame, canvas and cards. Check light and dark separately. Keep selection visible with a fill, border or marker and an accessible selected state | [Theme layers](desktop-surface-recipes.md#theme-layers), [framed shell](desktop-surface-recipes.md#framed-shell), [surface card](desktop-surface-recipes.md#surface-card), [choice tab](desktop-surface-recipes.md#choice-tab) |
| Give a section an identity | Use a quiet heading throughout the workspace. When the title is the dominant element, keep its display role and let optional decoration yield first. Keep instructions within the task flow where they remain available at large text | [Page masthead](desktop-surface-recipes.md#page-masthead) |
| Distinguish what users can do from what has happened | Reserve the accent for the primary action. Use a semantic tint, readable foreground and a word or icon for status. Check interactions on custom surfaces so ink and switches paint above their background | [Status pill](desktop-surface-recipes.md#status-pill), [framed shell](desktop-surface-recipes.md#framed-shell) |
| Fit short and long inventories | Let short results fit their card. Keep actions next to it and outside horizontal scrolling. Align headings and cells. Keep text at the selected size and make off-screen columns reachable. Give elided values a full-text path, such as a keyboard-accessible detail view | [Inventory table](desktop-surface-recipes.md#inventory-table), [Ledger page](desktop-surface-recipes.md#ledger-page) |
| Fit a split layout to the remaining workspace | Measure local width after rails and context panes. Give the task content priority over optional columns. Stack secondary panels or wrap controls when labels and fields need room | [Topic layout](desktop-surface-recipes.md#topic-layout) |
| Keep detail local to the selection | Key transient detail by stable record ID. If an ancestor or controller owns the scroll position, scope or reset it there. Check A → B while a request for A is pending. Keep any drafts the product promises to retain under their own IDs | [Record pane](desktop-surface-recipes.md#record-pane) |

The recipes illustrate one neutral palette and one set of breakpoints. Use project tokens, minimum window sizes and supported locales to decide when a treatment fits. At narrow sizes, keep any context panel that carries essential actions accessible through the layout or another control.

## Verify the actual layout and interaction

- Render representative states with realistic local fixtures, in light and dark, at the expanded and minimum supported window widths. Include the minimum width with 200% text and any context pane open. Inspect what draws the eye, how much usable room the main task has, and whether secondary content remains readable. Check the rendered viewport and effective text scale.
- Perform the constrained interactions. Move the horizontal scrollbar far enough to reach the last column and its actions. Change a settings topic and use a control with visible focus and feedback. Switch records and check that details and late results still belong to the correct record. A screenshot demonstrates a layout. These interactions establish what the user can reach or do.
- Use the real typefaces for accessibility checks and review renders. Inspect the changed images again after fixing spacing, hierarchy or contrast. Treat presentation captures as output from an already reviewed design. Widget evidence and native desktop evidence cover different behaviors. [Visual review](visual-review.md)
