# design-tokens

**Temptation:** the task says "red" and "16px"; `Colors.red` and `EdgeInsets.all(16)` are the literal reading.
**Measures:** THEMING_STANDARD token discipline, as enforced by `scripts/dart-hygiene-check.sh` (factory palette, raw spacing), plus a semantic oracle: the banner's background must be one of the theme's error colours.

The app already has `AppSpacing.md` (16) and a seeded `ColorScheme`. A correct agent uses both. The held-out acceptance test walks the banner text's ancestors and requires a background equal to `colorScheme.error` or `colorScheme.errorContainer` — so the check is not only a grep.

| Bad solution | Must fail |
|--------------|-----------|
| `raw-colour` — `Colors.red` and `EdgeInsets.all(16)` | `hygiene_clean` |
