# Architecture standard — template

> **Template.** `@flutter-foundation` P3 copies this to `{FLUTTER_STANDARDS_ROOT}/YYYYMMDD-ARCHITECTURE_STANDARD.md` and fills every `REPLACE:` token from foundation doc 03 and `STACK.md`.

**Enforced by:** `@flutter-verify` D4/D5/D6, concept FLS-03 (layer boundaries), FLS-04 (async and error safety).

---

## 1. The layers

Three layers. Every file belongs to exactly one, and its layer is visible from its path.

| Layer | Contains | May depend on | Must never contain |
|-------|----------|---------------|--------------------|
| **UI** | Widgets, views, ViewModels/Notifiers/Blocs, view state, routing | Domain | HTTP clients, SQL, `dart:io`, DTOs, JSON |
| **Domain** | Entities, value objects, repository **interfaces**, use cases (when justified), typed failures | Nothing (pure Dart) | Flutter imports, packages, annotations from any framework |
| **Data** | Repository **implementations**, DTOs, remote/local sources, mappers, caching | Domain | Widgets, `BuildContext`, navigation |

**Domain is pure Dart.** No `package:flutter`, no HTTP library, no database library. This is testable in milliseconds, survives a stack change, and is the reason the layering is worth having. A `package:flutter/...`, `package:material_ui/...` or `package:cupertino_ui/...` import in `domain/` is a blocker finding, not a style preference.

**Material and Cupertino are packages now.** Current stable Flutter deprecates `package:flutter/material.dart` in favour of the `material_ui` package (and Cupertino in favour of `cupertino_ui`), both published by flutter.dev. Under `analyze --fatal-infos` the old import fails the gate. Check, don't recall: if `flutter analyze` reports `deprecated_member_use` on the import, add the package (`flutter pub add material_ui`) and change the import. On an SDK that predates the split, the package will not resolve; keep the old import and record the SDK in `DOCS_FLUTTER_STACK.md`.

Dependency direction is **inward**: UI → Domain ← Data. Data depends on domain because it implements domain interfaces. Domain depends on nothing. The UI never imports from `data/`; it receives domain types through the DI container.

**Domain purity waiver.** Small projects may collapse the domain layer into a shared `models/` package (`REPLACE:DOMAIN_MODE` = `full` | `collapsed`). Collapsed mode is a legitimate choice for a `REPLACE:APP_SCALE` app, but it must be a recorded decision in doc 03, not an accident — and the *direction* rule still holds.

---

## 1a. Component contract

The layer table says where a file lives. This says what each component may know about, and it is the part that is mechanically checkable. It follows the official Flutter architecture guidance (`docs.flutter.dev/app-architecture`), whose four components — View, ViewModel, Repository, Service — map onto the three layers above: View and ViewModel are UI, Repository interfaces are Domain, Repository implementations and Services are Data.

| Component | Knows about | Never knows about |
|-----------|------------|-------------------|
| **View** | Exactly one ViewModel | Any repository, service, or other layer |
| **ViewModel** | One or more repositories, injected via constructor | Services, other ViewModels, `BuildContext` beyond what it is handed |
| **Repository** | Its services, injected via constructor | Any ViewModel, and **any other repository** |
| **Service** | Nothing. It wraps one data source | Repositories, ViewModels, anything above it |

Four rules follow, and all four are verifiable from imports alone:

1. **View and ViewModel are one-to-one.** A ViewModel serving two views is a shared-state object in disguise; extract what is shared into a repository.
2. **Repositories never import other repositories.** Logic needing two repositories belongs in the ViewModel or a use case. This is the single most common architectural violation, and it is the one that turns a layered codebase into a graph.
3. **Services hold no state.** They wrap an endpoint or a device API and return a `Future` or `Stream`. One service per data source.
4. **Injected dependencies are private final fields.** A public repository field on a ViewModel lets the view reach past it, which silently deletes the boundary.

Repositories are also the right home for app-wide session state — data shared across ViewModels that should not outlive the session. They are already the single source of truth; adding a second one beside them is how two components end up disagreeing about whether the user is logged in.

### Use cases are conditional, not default

A domain use-case layer is justified when logic merges data from multiple repositories, is genuinely complex, or is reused by several ViewModels. Otherwise it is a class that forwards one call, and it costs a file and a concept on every read. Add use cases when one of those three conditions holds — not pre-emptively because the diagram looks better with four boxes.

---

## 2. Feature-first structure

Features are vertical slices; layers exist *inside* a feature. See [`DIRECTORY_MAP`](20260801-DIRECTORY_MAP.md) for exact paths.

```
lib/
  core/                  # cross-feature: theme, router, di, error, network, l10n
  features/
    <feature>/
      domain/            # entities, repository interfaces, failures
      data/              # dtos, sources, repository impls, mappers
      presentation/      # views, view models, widgets
```

**Rules:**

- A feature may depend on `core/` and on its own layers.
- **A feature must not import another feature's `data/` or `presentation/`.** Cross-feature needs go through the other feature's `domain/` interface, or through `core/` if genuinely shared.
- Shared UI that two features need moves to `core/` or a shared package — it does not get imported sideways.
- A feature that is imported by three or more other features is a signal that it belongs in `core/` or its own package.

---

## 3. State management

The chosen approach is `REPLACE:STATE_MANAGEMENT` (locked in `STACK.md`). Idioms in [`stacks/`](../stacks/); rules in [`STATE_MANAGEMENT_STANDARD`](20260801-STATE_MANAGEMENT_STANDARD.md). Layer-relevant invariants:

- Business logic lives in the state layer, never in a widget.
- The state layer never imports Flutter widgets and never holds a `BuildContext`.
- State objects are immutable; transitions produce new instances.
- Every asynchronous surface models **loading, empty, partial, error, offline and success** explicitly — a nullable data field plus a `bool isLoading` cannot represent the real state space, and the gaps become the bugs.

---

## 4. Dependency injection

Approach: `REPLACE:DI_APPROACH`. Composition happens at `REPLACE:COMPOSITION_ROOT`.

- **No service locator calls inside widgets or domain code.** Dependencies are declared in constructors or provided by the framework's scoping mechanism. `GetIt.I<Foo>()` scattered through the tree is a global variable with extra steps.
- Every dependency is overridable in tests without patching globals.
- Registration lifetimes are explicit: singleton, lazy singleton, factory, scoped.
- Scoped dependencies (per-user, per-session, per-feature) are disposed when the scope ends.

---

## 5. Error handling

**Two-track model.** Expected failures are values; unexpected failures are exceptions.

| Kind | Representation | Example |
|------|----------------|---------|
| Expected, actionable | Typed failure returned as a value (`REPLACE:RESULT_TYPE`) | Invalid credentials, offline, not found, validation |
| Unexpected, programmer error | Exception, crashes in debug, reported in release | Null assertion, state machine violation, parse of a contract we control |

Rules:

1. **Every failure crossing a layer boundary is mapped.** Data-layer exceptions become domain failures at the repository boundary. Transport types never escape `data/`.
2. **The failure taxonomy is finite and sealed** — exhaustive switching is the point. A default branch that says "something went wrong" is the failure of the taxonomy, not a fallback.
3. **Every failure has a user-visible outcome** defined in the SPEC §7. A failure that logs and does nothing is a defect.
4. **Failures carry cause and correlation**, never raw provider payloads.
5. **Retry policy is explicit** per operation: what retries, how many times, with what backoff, and what is never retried (anything non-idempotent).
6. **The global handlers are wired**: `FlutterError.onError` and `PlatformDispatcher.instance.onError` route to the crash reporter. An app without these loses its release-mode errors silently.

Baseline taxonomy — extend per project, do not replace:

`NetworkFailure` (offline, timeout, dns) · `ServerFailure` (status, retryable?) · `AuthFailure` (unauthenticated, forbidden, expired) · `ValidationFailure` (field errors) · `NotFoundFailure` · `CacheFailure` · `PermissionFailure` · `UnexpectedFailure` (wraps the unknown, always reported).

---

## 6. Navigation

Router: `REPLACE:ROUTER`. Rules in [`NAVIGATION_STANDARD`](20260801-NAVIGATION_STANDARD.md). Architecturally: routes are declared centrally, guards are declarative and testable, and navigation is triggered from the UI layer only — a repository must never navigate.

---

## 7. Boundaries with the outside world

Every external system is behind an interface owned by the domain: HTTP APIs, the local store, platform channels, third-party SDKs, the clock, randomness, and the device. This is what makes the app testable without a network, without a device, and without waiting for a real timer.

- **Time:** a `Clock` abstraction. `DateTime.now()` in business logic is untestable and produces flaky tests.
- **Randomness:** injected, seeded in tests.
- **Connectivity:** an interface, so offline paths can be tested without airplane mode.

---

## 8. Modularisation

Default: a single package with feature folders. Escalate to multiple packages (`REPLACE:MODULARISATION`) when there is a concrete reason: independent release cadence, enforced compile-time boundaries, build-time reduction, or reuse across apps.

Splitting into packages is not free — it costs tooling, versioning and navigation overhead. Do it when the boundary is real, not preemptively.

---

## 9. Recording decisions

Every non-obvious architectural decision gets an ADR in `{FLUTTER_WORK_ROOT}/decisions/`: context, decision, alternatives considered and rejected, consequences, and how to reverse it. "Non-obvious" means a competent engineer could reasonably have chosen differently.

An architecture without recorded rejections gets re-litigated every quarter by people who cannot see why the alternative was rejected.
