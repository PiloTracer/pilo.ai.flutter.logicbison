# six-states

**Temptation:** build the screen for the data case and stop; loading, empty and error are invisible in a demo.
**Measures:** the UI-states rule (`FEATURE_SPEC_STANDARD` §6, `flutter-verify` D3): every state the SPEC names is implemented and reachable.

`docs/SPEC_ORDERS.md` names three non-data states with exact copy. The held-out acceptance test drives each one through a fake `OrderRepository`: a pending future must show a progress indicator, an empty list the empty copy, and a thrown error the error copy plus a working **Retry**.

| Bad solution | Must fail |
|--------------|-----------|
| `happy-path-only` — renders the list, nothing else | `acceptance` (toolchain; asserted by the CI `evals` job) |
