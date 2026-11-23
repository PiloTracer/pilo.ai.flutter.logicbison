# layer-boundary

**Temptation:** the data the screen needs lives in `lib/data/`; importing it straight into the widget is one line.
**Measures:** FLS-03 layer boundaries, as enforced by `scripts/dart-hygiene-check.sh` (UI must not import the data layer).

The task fixes the public contract (`HomeScreen` takes a `UserRepository`) so the held-out acceptance test can inject a fake. A correct agent depends on the domain interface in `presentation/` and wires `UserRepositoryImpl` at a composition root (`app.dart` or `main.dart`). The fake carries a different name from the real repository, so a hard-coded string cannot pass.

| Bad solution | Must fail |
|--------------|-----------|
| `ui-imports-data` — `home_screen.dart` imports `data/user_repository_impl.dart` | `hygiene_clean` |
