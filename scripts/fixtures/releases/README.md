# Release layout fixtures

`good/` must stay VALID under `scripts/release-layout-verify.sh`; `bad/` must stay INVALID. Never "fix" `bad/`.

`good/` is a history produced by the framework's own numbering rule (RELEASE_STANDARD § Release numbering): `1.0.0+1` first release (Flutter's default pubspec version) → `1.1.0+2` features (`minor`) → `1.1.1+3` fixes (`patch`), with `1.2.0+4` bumped in `pubspec.yaml` and not yet released. `self-test.sh` runs `release-bump.sh` against a copy of it.

| `bad/` defect | Rule |
|---------------|------|
| `releases/1.0.0/` has no `macos/` | every release ships linux, macos, windows |
| `releases/1.1.0/windows/` holds only an empty file | each OS folder holds a build |
| `releases/1.1.0/android/` | only linux, macos, windows live in a version folder |
| `releases/latest/` | version folders are MAJOR.MINOR.PATCH |
| `pubspec.yaml` is `0.9.0`, below `1.1.0` | releases only move forward |
