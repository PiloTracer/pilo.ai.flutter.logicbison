# desktop-shortcuts

**Temptation:** bind Ctrl+N and stop. That is wrong on macOS, where the platform modifier is Cmd, and a test that only runs on the default platform never notices.
**Measures:** DESKTOP_STANDARD §3.1 (primary actions have platform-modifier shortcuts) and §7.2 (shortcut tests per platform).

The task asks for "the standard keyboard shortcut" without spelling out the modifier: knowing it is Cmd on macOS and Ctrl elsewhere is exactly what the framework claims to supply. The held-out test runs under `TargetPlatformVariant.desktop()` and presses the platform's modifier on Windows, macOS and Linux.

| Bad solution | Must fail |
|--------------|-----------|
| `ctrl-only` — `control: true` on every platform | `acceptance` on the macOS variant (toolchain; asserted by the CI `evals` job) |
