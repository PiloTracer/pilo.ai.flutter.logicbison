---
name: flutter-data
description: >-
  Own the Flutter data layer - domain entities, DTOs and serialization,
  repository interfaces and implementations, remote and local sources, caching
  and offline policy, and versioned local-store migrations. Every schema change
  goes through this skill so migrations stay ordered, idempotent and tested.
  Use for model this JSON, add a repository, cache responses, local database,
  or migrate stored data.
---

# flutter-data

The data layer is where correctness is won or lost: it decides what is true, where truth lives, and what happens when the device and the server disagree. This skill owns it so those decisions are made once and recorded.

**Pairs with:** `flutter-implementation` (delegates here for any data work), `flutter-stack` (K4 serialization, K5 HTTP, K6 local store), `flutter-test` (data-layer tests), `flutter-security` (storage classification), `flutter-foundation` (doc 04 is the source of truth).

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Standard:** [`DATA_LAYER_STANDARD`](../../standards/20260801-DATA_LAYER_STANDARD.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Domain entities never know about JSON, HTTP or the database.** DTOs live in `data/`, entities live in `domain/`, and mapping is explicit. A `fromJson` on a domain entity is a layering violation.
2. **The repository interface lives in `domain/`, the implementation in `data/`.** The domain depends on the abstraction; the abstraction never leaks a transport type.
3. **Every local-store change is a numbered, idempotent migration.** Never mutate a schema in place, never reorder existing migrations, never edit a shipped one.
4. **Every migration is verified by running it twice.** Second run must be a no-op. Unverifiable → say so; do not claim it.
5. **Nothing sensitive in plain local storage.** Classify per doc 04 §5; credentials and tokens go to the platform keystore/keychain via secure storage, never to preferences or an unencrypted database.
6. **Errors cross the boundary as typed failures**, not as raw exceptions from `dio`, `http`, or the database driver. The presentation layer must never `catch` a transport exception.
7. **Cache policy is explicit per entity.** Staleness tolerance, eviction and offline writability come from doc 04 §4 — never improvised at the call site.
8. **Generated code is committed and current.** After any annotated change, run the generator and commit the output.

---

## Modes

| Mode | Action |
|------|--------|
| `model - <entity>` | Domain entity + DTO + mapping + tests, per the locked serialization choice |
| `repository - <slug>` | Repository interface (domain) + implementation (data) + tests |
| `source - <slug> <remote\|local>` | A data source with its error mapping and tests |
| `cache - <entity>` | Apply the cache and staleness policy for an entity |
| `migration - <description>` | A new numbered local-store migration + its test |
| `verify` | Read-only: run migrations twice, check idempotency, round-trip serialization, layering |
| `audit` | Read-only: layering violations, unmapped errors, unclassified storage, missing tests |
| `status` | Read-only: entities, repositories, sources, migration history |

---

## Prerequisite gate (D0)

```markdown
## @flutter-data <mode> - blocked (prerequisite)

**Required:** a locked stack (K4 serialization, K6 local store) and either an active
iteration task or an explicit operator request
**Detected:** <what is missing>
**Run first:** `@flutter-stack set` | `@flutter-implementation plan - F{N}`
```

---

## model protocol

1. **Read doc 04** for the entity's attributes, invariants, source of truth and lifetime. Not in doc 04 → route to `@flutter-foundation continue` (P4). Do not invent a domain model.
2. **Write the domain entity** in `lib/src/features/<slug>/domain/`: immutable, value equality, invariants asserted in the constructor, no serialization, no transport types.
3. **Write the DTO** in `data/dto/`: mirrors the wire format exactly, including the server's naming and nullability. Do not "clean up" the API shape here — that is what mapping is for.
4. **Write the mapping** both ways, explicitly, in one place. Unknown enum values map to a defined fallback, never to a crash.
5. **Run the generator** when the locked choice uses codegen; commit the output.
6. **Tests:** round-trip (`dto → json → dto`), mapping (`dto → entity`), invariant violations rejected, null and missing fields, unknown enum fallback, and a real captured API payload as a fixture.

**Nullability discipline:** if the server *can* omit it, the DTO field is nullable and the mapping decides the default. A non-nullable DTO field that the server omits is a production crash, not a compile error.

---

## repository protocol

1. **Interface in `domain/`.** Methods return the project's typed outcome (Result/Either per ARCHITECTURE_STANDARD) over domain entities. No DTOs, no `Response`, no `Exception` in the signature.
2. **Implementation in `data/`.** Composes remote and local sources, applies the cache policy, maps transport errors to typed failures, and maps DTOs to entities.
3. **Error mapping is total.** Every transport exception class maps to a named failure. A bare `catch (e)` that returns a generic failure loses the information the UI needs to choose a message.

| Transport condition | Failure |
|---------------------|---------|
| No connectivity / DNS / socket | `NetworkFailure` |
| Timeout (connect, send, receive) | `TimeoutFailure` |
| 401 / 403 | `AuthFailure` (distinguish expired from forbidden) |
| 404 | `NotFoundFailure` |
| 409 | `ConflictFailure` |
| 422 / validation body | `ValidationFailure` with field errors |
| 429 | `RateLimitFailure` with retry-after |
| 5xx | `ServerFailure` |
| Malformed body / parse error | `ParseFailure` — log the shape, never the payload |
| Cancelled | `CancelledFailure` — not an error to surface |

4. **Tests:** one per failure mapping, cache hit and miss, stale-while-revalidate if used, and offline behaviour per doc 04 §4.

---

## source protocol

**Remote source:** owns the transport. One method per endpoint, returns DTOs, throws or returns transport-level errors that the repository maps. Interceptors (auth, retry, logging) are configured once in `core/network/`, not per source. Logging must redact per OBSERVABILITY_STANDARD.

**Local source:** owns persistence. Reads and writes DTOs or store rows, never domain entities directly unless the store is the source of truth. Chosen per K6:

| Data shape | Store |
|------------|-------|
| Small key-value, non-sensitive, no query | `shared_preferences` |
| Credentials, tokens, anything sensitive | secure storage (keystore / keychain) |
| Relational, queryable, joins, reactive queries | a typed SQL layer (K6 choice) |
| Simple documents, no relations | the K6 document/SQLite choice |
| Large binaries | the filesystem, with paths recorded — never a database blob |

---

## migration protocol

Local-store schema changes are the highest-risk thing in a mobile app: users carry old data forward, and a bad migration bricks the install.

1. **Never edit a shipped migration.** Add a new one.
2. **Numbering:** `NNN_snake_case_description` — zero-padded, strictly increasing, never reused or reordered.
3. **Idempotent:** guard every operation so a second run is a no-op.
4. **Forward-only.** No down-migrations on device; a mistake is fixed by a new forward migration.
5. **Data-preserving by default.** Any destructive step requires explicit operator confirmation, recorded in the migration's header comment and in the report.
6. **Test with real old data.** A fixture of the *previous* schema, populated, migrated, and asserted — not an empty database.
7. **Handle the skip case.** A user on version 3 upgrading to version 7 runs 4, 5, 6 and 7 in order. Test that path, not just the adjacent one.

**Auto-invoked verification** (per [SKILL_DEPENDENCIES § Self-verify](../SKILL_DEPENDENCIES.md#self-verify-auto-invoke)): after creating a migration, run `verify` before reporting complete. Store unreachable → report `not run (<reason>)`.

**Migration record** — append to `{FLUTTER_WORK_ROOT}/plans/operations/migrations.md`:

| # | Description | Schema version | Destructive | Tested from | Added |
|---|-------------|----------------|-------------|-------------|-------|

---

## verify protocol

Read-only. Runs the mechanical data-layer checks.

| # | Check | Method | Fail |
|---|-------|--------|------|
| V1 | Migration idempotency | Run the full chain twice on a fixture | Second run changes state |
| V2 | Skip-version path | Migrate from each shipped version to current | Any path errors |
| V3 | Serialization round-trip | `dto → json → dto` for every DTO | Any mismatch |
| V4 | Real-payload parsing | Parse every captured fixture | Any parse error |
| V5 | Null and missing fields | Parse with each optional field absent | Crash instead of default |
| V6 | Unknown enum fallback | Parse an unrecognised enum value | Throw instead of fallback |
| V7 | Layering | Grep `domain/` for transport and serialization imports | Any hit |
| V8 | Error totality | Every failure class reachable from a mapped condition | An unmapped exception path |
| V9 | Storage classification | Every stored field appears in doc 04 §5 | Unclassified storage |
| V10 | Secure storage usage | Nothing classed sensitive in plain storage | Any hit |

---

## audit protocol

Read-only, broader than `verify`. Findings table `ID | Layer | Severity | Finding | Path | Fix`. Adds: repositories with no test, entities not in doc 04, DTOs with no fixture, cache policies not stated in doc 04 §4, sources bypassed by direct HTTP calls from the presentation layer, and `dynamic` in a data signature.

Route to `@flutter-repair repair - from data-audit`.

---

## Anti-patterns

- `fromJson` / `toJson` on a domain entity.
- A repository interface that returns a transport type or throws a transport exception.
- `catch (e)` returning a single generic failure for every condition.
- Editing a shipped migration.
- Testing a migration against an empty database.
- Storing a token in `shared_preferences`.
- Making a DTO field non-nullable because the server "always" sends it.
- Throwing on an unknown enum value from the server.
- Improvising a cache TTL at the call site.
- Calling an HTTP client directly from a widget or view model.
- Leaving generated files stale after changing an annotated source.
- Logging a full response body that may contain personal data.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | D0 gate passed | pass/fail | |
| 2 | doc 04 read; entity/policy sourced, not invented | pass/fail | § ref |
| 3 | Domain free of serialization and transport | pass/fail | grep |
| 4 | Repository interface in domain, impl in data | pass/fail | paths |
| 5 | Error mapping total; every failure named | pass/fail | table |
| 6 | Nullability matches the real wire contract | pass/fail | fixture |
| 7 | Cache policy from doc 04 §4 | pass/skip | |
| 8 | Storage classification honoured; secrets in secure storage | pass/fail | |
| 9 | Migration numbered, idempotent, forward-only | pass/skip | number |
| 10 | Migration tested from a populated old-schema fixture | pass/skip | test path |
| 11 | Skip-version path tested | pass/skip | |
| 12 | `verify` auto-invoked; result quoted | pass/fail/not run | |
| 13 | Generated code regenerated and committed | pass/skip | files |
| 14 | Tests written for every new unit | pass/fail | paths |
