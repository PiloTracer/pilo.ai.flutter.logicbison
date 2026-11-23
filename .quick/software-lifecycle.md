# Software lifecycle with Flutter Agent OS

| Phase | What you do | Skills |
|-------|-------------|--------|
| **Create / adopt** | Install framework + scaffold `.work.flutter/` | `@flutter-deploy-basic` / `@flutter-deploy-files`, `@flutter-bootstrap init` / `quickstart` |
| **Lock stack** | Choose state, nav, DI, data, testing | `@flutter-stack probe` → `set` |
| **Plan** | Foundation, master plan, SPECs | `@flutter-foundation`, `@flutter-plan-master`, `@flutter-feature-spec` |
| **Scaffold** | App / module / CI skeletons | `@flutter-scaffold` |
| **Develop** | Milestone tasks in `NEXT_FLUTTER.md` | `@flutter-implementation start/continue` |
| **Track** | Session + backlog truth | `@flutter-session`, `HANDOFF_FLUTTER.md`, `NEXT_FLUTTER.md` |
| **Verify** | Gates, diffs, concepts | `@flutter-verify`, `@flutter-plan-verify`, `gate-verify.sh`, last-gate.json |
| **Debug / fix** | Close verifier gaps; toolchain | `@flutter-repair`, `@flutter-doctor` |
| **Follow-up** | Hand off to next session | `@flutter-session close` |
| **Improve** | Architecture / NFR / craft lenses | `@flutter-concept-run`, FLS packs |
| **Deliver** | Release + store | `@flutter-release certify` → `build` → `distribute` |

```text
create → stack → plan → scaffold → develop ⇄ verify → repair → track → deliver → improve
                         ↑____________ flutter-session bookends ____________|
```

**Lost?** `@flutter-router - <question>` or `@flutter-director - <goal>`.
