# adaptive-layout

**Temptation:** `MediaQuery.of(context).size.width > 800` inside the widget: the whole-screen size (wrong inside any pane), a full rebuild on every metrics change, and a magic number.
**Measures:** DESKTOP_STANDARD §5 (layout follows the window via `LayoutBuilder` / `MediaQuery.sizeOf`; breakpoints are tokens) and §7.1 (tests set the window size).

The theme already defines `AppBreakpoints.expanded`. The held-out tests resize the test window: wide shows list and detail side by side with a placeholder, narrow keeps push navigation, and the boundary sits exactly on the token (840 is wide, 839 is not).

| Bad solution | Must fail |
|--------------|-----------|
| `mediaquery-size` — width from `MediaQuery.of(context).size` | `hygiene_clean` |
