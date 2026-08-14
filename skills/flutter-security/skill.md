---
name: flutter-security
description: >-
  Audit and harden the security and privacy posture of a Flutter application -
  secrets in source and in the shipped bundle, credential and sensitive-data
  storage, transport security and pinning, permissions and privacy
  declarations, dependency advisories, platform hardening, obfuscation, and
  logging hygiene. Use for secrets, secure storage, certificate pinning,
  vulnerable dependency, privacy, or a pre-launch security review.
---

# flutter-security

Mobile clients are shipped to attackers. This skill assumes the binary will be unpacked, the traffic intercepted and the device rooted, then checks what that would expose.

**Pairs with:** `flutter-data` (storage classification), `flutter-platform` (permissions, native config), `flutter-release` (R3, R7, R8 gates), `flutter-verify` (D11), `FLS-11 security and privacy`.

**Registry:** [`SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md) · **Standard:** [`SECURITY_PRIVACY_STANDARD`](../../standards/20260801-SECURITY_PRIVACY_STANDARD.md)

**Contracts:** [Operator handoff](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — close every response with Form A or Form B.

**Hard rules:**

1. **Never echo a discovered secret.** Report the file, the line and the *kind* of secret. Printing the value into a report, a log or a commit message spreads the exposure.
2. **A client-side secret is not a secret.** `--dart-define`, compiled constants, obfuscated strings and asset files are all extractable from a shipped bundle. The only correct answer for a real secret is "it lives server-side". Say this plainly rather than suggesting a hiding place.
3. **Client-side controls are defence in depth, never enforcement.** Root detection, pinning and obfuscation raise cost; they do not establish trust. Every authorisation decision is the server's.
4. **A leaked credential is revoked, not deleted.** Removing it from the working tree leaves it in git history and in every clone. The finding is `high` until it is rotated, and the report must say so.
5. **Only free, OSS, commercial-use-permitted tooling** is recommended, per [`PACKAGE_LICENSE_STANDARD`](../../standards/20260801-PACKAGE_LICENSE_STANDARD.md).
6. **Never claim a check you did not run**, and never soften a `high` finding because the release is close.

---

## Modes

| Mode | Action |
|------|--------|
| `audit` | Full read-only review across all eight areas |
| `secrets [target]` | Scan source, config, assets, history and (when available) the built artifact |
| `storage` | Verify every stored field against its classification in doc 04 §5 |
| `transport` | TLS, cleartext, pinning, ATS/network-security config, WebView settings |
| `deps` | Dependency advisories, licenses, maintenance and transitive risk |
| `permissions` | Declared vs used vs justified in SPEC §11; privacy declarations |
| `harden - <area>` | Apply a specific hardening measure from a finding |
| `status` | Read-only: last audit, open findings, what is stale |

---

## audit protocol — the eight areas

### 1. Secrets

| Check | Fail |
|-------|------|
| Source, tests, fixtures, comments | Any API key, token, password, private key, connection string |
| `--dart-define` files and flavor configs | A real secret rather than a public identifier |
| Assets and bundled JSON | Credentials in a shipped file |
| Native config (`Info.plist`, manifest, Gradle, `.xcconfig`) | Embedded keys |
| Git history | Any of the above ever committed, even if since removed |
| Tracked signing material | `key.properties`, `*.jks`, `*.keystore`, `*.p12`, `*.mobileprovision`, service-account JSON |
| The built artifact (when available) | Strings extractable from the bundle |

**A public identifier is not a secret.** A Firebase app id or a public analytics key is fine. An API key with server-side authority, a signing key, or a database credential is not. Classify, do not blanket-flag.

**On any hit:** severity `high`, action = **rotate the credential**, then remove it, then move it server-side or into CI secrets. Never report "removed from the file" as resolution.

### 2. Storage

Every persisted field must appear in doc 04 §5 with a class, and be stored accordingly:

| Class | Correct storage | Wrong |
|-------|-----------------|-------|
| Public | Anywhere | — |
| Internal | Local database or preferences | — |
| Personal data | Local store, encrypted at rest if the regime requires it; deletable on account deletion | Logs, analytics payloads |
| Sensitive (health, financial, precise location) | Encrypted store with an explicit retention rule | Preferences, plain files |
| Credential (token, refresh token, key) | Platform keystore / keychain via secure storage | Preferences, plain database, memory-only caches that get serialised |

Also check: no sensitive data in a plaintext cache; backups excluded where required (Android `allowBackup`, iOS backup exclusion); data actually deleted on logout and on account deletion; screenshots/task-switcher protection where the regime requires it.

### 3. Transport

| Check | Requirement |
|-------|-------------|
| All endpoints HTTPS | No `http://` outside tests and localhost dev |
| Android cleartext | Disabled in release; a network-security config that does not permit user CAs in release |
| iOS ATS | No blanket `NSAllowsArbitraryLoads`; each exception justified in writing |
| Certificate pinning | Applied where SECURITY_PRIVACY_STANDARD requires it, with a **rotation plan** — pinning without one is a self-inflicted outage |
| Certificate validation | No `badCertificateCallback` returning true, no custom `HttpOverrides` disabling validation. This is `high` even in debug-only code, because debug-only code ships |
| WebView | JavaScript enabled only when needed; no `file://` access to app storage; navigation restricted to an allowlist; no bridge exposing native capability without validation |
| Auth token handling | Not in URLs or query strings; not logged; refresh handled without a race that double-refreshes |

### 4. Dependencies

Enumerate direct and transitive dependencies and report: known advisories, license compliance, discontinued or unmaintained packages, packages with native code from an unknown publisher, and packages whose declared permissions exceed what the app needs. Check the lockfile is committed for apps. Flag any dependency that pulls in a networking or analytics capability the product did not ask for.

**There is no `flutter pub audit` or `dart pub audit`.** Do not write that command; it does not exist, and inventing it produces a CI step that fails or a claim with nothing behind it.

What does exist:

| Mechanism | What it gives you |
|-----------|-------------------|
| `dart pub get` | Prints advisories for known-vulnerable dependencies — **and exits 0 regardless**. Informational, easily lost in CI logs, never a gate |
| `dart pub outdated` | Version drift, not vulnerabilities. Useful, different question |
| OSV-Scanner / Trivy (both Apache-2.0) | The actual gate. Reads `pubspec.lock`, exits non-zero on findings |

Run a real scanner as its own step and quote its output. If no scanner is available, report `not run` — a dependency set nobody scanned is unknown, not clean, and reporting it as clean is the same category of false statement as an unrun test reported as passing.

### 5. Permissions and privacy

| Check | Fail |
|-------|------|
| Declared ⊆ used | A permission in the manifest or plist with no code path that needs it |
| Used ⊆ declared | A capability invoked without a declaration (runtime failure) |
| Each declaration justified in SPEC §11 | No SPEC entry |
| iOS usage strings specific and localised | Generic or missing |
| Privacy declarations match doc 04 §5 | A data type collected but not declared, or declared but not collected |
| Third-party SDK collection disclosed | An analytics or ads SDK collecting undeclared data |

### 6. Platform hardening

Release builds: obfuscation enabled with symbols retained; debug flags off; no debuggable release; R8/Proguard rules not over-broad; iOS entitlements minimal; exported Android components (`activity`, `service`, `receiver`, `provider`) intentional and permission-guarded; deep-link input validated; no debug backdoor route reachable in release.

Root/jailbreak detection and integrity checks are optional and only where the threat model justifies them — record the decision either way rather than leaving it implicit.

### 7. Logging and observability

No credentials, tokens, personal data, precise location or full request/response bodies in logs. Redaction applied at the logger, not at each call site. Crash reports scrubbed. Analytics events carry no personal data unless doc 04 §5 explicitly permits it. Verbose logging disabled in release.

### 8. Input and injection

Deep-link parameters validated. Local database queries parameterised, never string-concatenated. File paths from external input canonicalised and confined. WebView content sanitised. Any dynamic code or template evaluation treated as a `high` finding.

---

## harden protocol

Apply a specific measure from a finding. Every hardening change:

1. States the threat it addresses and the residual risk it does not.
2. Is verified after application — re-run the relevant audit area and quote the result.
3. Records a rotation or maintenance plan when it introduces one (pinning especially).
4. Never breaks the debug loop silently — if a measure makes local development harder, say how developers work around it legitimately.

---

## Report shape

```markdown
## @flutter-security <mode>

**Scope:** <source | source + artifact> · **Artifact:** <path or not built>

| Area | Result | Findings |
|------|--------|----------|
| 1 Secrets | fail | 1 high |
| 2 Storage | pass with gaps | 1 med |
| 4 Dependencies | not run | scanner unavailable |

### Findings
| ID | Area | Severity | Finding | Location | Required action |
|----|------|----------|---------|----------|-----------------|
| S1 | secrets | high | API key committed (kind: bearer token) | `lib/src/core/network/api_client.dart:23` **and git history** | **Rotate the key**, move server-side, purge from history |

**Verdict:** pass | pass with gaps | fail
**Blocking release:** <ids or none>

### Route
| Finding | Run next |
|---------|----------|
| S1 | Rotate externally, then `@flutter-security harden - secrets` |
```

End the report with the Operator handoff close (Form A `Next: …` or Form B `**Needs your approval:**` / `**Needs your answer:**` / `**Next step:**`) per [`SKILL_DEPENDENCIES.md` § Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract).

---

## Anti-patterns

- Printing a discovered secret into the report.
- Suggesting obfuscation or `--dart-define` as a way to keep a client secret.
- Reporting a leaked key as fixed once it is deleted from the working tree.
- Trusting a client-side check as an authorisation decision.
- Pinning certificates with no rotation plan.
- A `badCertificateCallback` that returns true, gated on a debug flag.
- Declaring permissions "in case we need them later".
- Copying privacy declarations from another app.
- Logging a full response body "temporarily".
- Downgrading a `high` finding because the release is tomorrow.
- Reporting dependencies clean when no scanner ran.
- Recommending a paid or non-commercial-licensed security tool.

---

## Completion checklist

| # | Check | Result | Evidence |
|---|-------|--------|----------|
| 1 | Scope stated (source only, or source + artifact) | pass/fail | |
| 2 | All eight areas evaluated or explicitly `not run` | pass/fail | table |
| 3 | Secrets scan covers source, config, assets, history | pass/fail | |
| 4 | No secret value echoed | pass/fail | |
| 5 | Every stored field classified per doc 04 §5 | pass/fail | |
| 6 | Credentials in platform secure storage | pass/fail | |
| 7 | Transport checks incl. certificate validation | pass/fail | |
| 8 | Dependency advisories checked, or `not run` with reason | pass/not run | tool |
| 9 | Permissions reconciled three ways (declared/used/justified) | pass/fail | |
| 10 | Privacy declarations traced to doc 04 §5 | pass/fail | |
| 11 | Every `high` finding names rotation/remediation, not deletion | pass/skip | |
| 12 | Findings routed; nothing fixed silently | pass/fail | |
