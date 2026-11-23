# Onboarding in 30 minutes (lite path)

**Goal:** Working `.work.flutter/` memory + honest gates on an **existing** Flutter repo (framework already installed).

```text
@flutter-bootstrap init                   # once: creates .work.flutter/ (quickstart needs it)
@flutter-bootstrap quickstart - lite      # writes plans/QUICKSTART-PLAYBOOK.md
@flutter-bootstrap status                 # unfilled REPLACE: tokens
@flutter-session start
# edit .work.flutter/plans/NEXT_FLUTTER.md — one Recommended next row
# implement one small change
@flutter-verify uncommitted
@flutter-session close
```

`quickstart` never creates `.work.flutter/`; run before `init` it stops and routes you there.

**Stack:** `@flutter-stack probe` → `@flutter-stack set` when technology choices are ready (writes `STACK.md`).

**CI:** `@flutter-scaffold ci` when ready for PR checks (canonical workflow: `templates/ci/github-actions/flutter-gates.yml`).

**Full lifecycle map:** [`.quick/software-lifecycle.md`](software-lifecycle.md)

**Lost?** `@flutter-router - <question>` or `@flutter-director - <what you want>`.
