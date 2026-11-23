# FLS-07 — Platform parity

**Fires:** platform channels, permissions, native configuration, platform-conditional code, plugins; and before every release.
**Owned with:** `@flutter-platform parity`.

---

## Why

Flutter makes it easy to forget that you are shipping several applications. The parity failures are almost never in the Dart code — they are a permission declared on Android and not iOS, a channel method implemented on one side, a deep link that works because the developer only ever tested on one device. They surface in store review or in a one-star review, both after the fact.

**Divergence is fine. Undeclared divergence is the defect.**

---

## Questions

**Capability matrix**

1. List every capability the change adds or touches. For each target platform: implemented, degraded, or absent?
2. For every non-implemented cell: is the divergence **declared** in the SPEC §11, and does the UI reflect it (feature hidden, disabled with an explanation, or an alternative offered)?
3. Does anything silently no-op on a platform? A silent no-op is the worst outcome — the user believes it worked.

**Channels**

4. Is every Dart-side method implemented on every platform the app ships to?
5. Is the channel contract typed and versioned, or is it ad-hoc maps?
6. Does each native side return **structured errors** with codes the Dart side handles, or does a failure surface as a raw `PlatformException`?
7. What happens when the platform side is missing entirely — an older app version, a platform not implemented?
8. Are argument types identical on both sides, including the numeric and null representations?

**Permissions**

9. Is every permission declared on every platform that needs it, with the required usage-description strings?
10. Are the three outcomes handled per platform — granted, denied, permanently denied? The permanently-denied path differs materially between iOS and Android.
11. Is mid-session revocation handled?
12. Is any permission declared but not used? (A store-review risk and a privacy finding.)

**Native configuration**

13. Which native files changed, and was the equivalent change made on the other platforms?
14. Minimum OS versions: does the change require raising one? Was doc 02 §1 checked?
15. Are entitlements, capabilities, URL schemes and background modes configured on every platform that needs them?

**Platform behaviour differences**

16. Back navigation: Android hardware/predictive back versus iOS swipe.
17. Lifecycle: how each platform backgrounds, suspends and terminates, and what state is lost.
18. Keyboard, safe areas, notches, and display cutouts.
19. Text rendering, fonts and default scale factors.
20. File system layout and available paths.
21. Notification behaviour and permission timing.

**Verification**

22. Which platforms was this actually run on? Model, OS version, and build mode.
23. Which platforms were **not** verified, and why?

---

## Output

| Capability | Android | iOS | Web | Windows | macOS | Linux | Divergence declared? | Verified on |
|------------|---------|-----|-----|---------|----------------------|-------------|

Plus findings with file and line, and an explicit list of platforms not verified.

---

## Verdict rules

| Condition | Severity |
|-----------|----------|
| A channel method implemented on one platform only | blocker |
| Silent no-op on a target platform | blocker |
| Permission missing or usage description missing | blocker |
| Undeclared divergence | blocker |
| Native config changed on one platform only | blocker |
| Permanently-denied path unhandled | major |
| Unstructured platform errors | major |
| Declared but unused permission | major |
| Minimum OS raised without checking doc 02 | major |
| Untested platform | reported, never inferred |

**A platform that was not run on is `unverified`, not `pass`.** Reporting an iOS result from a machine that cannot build iOS is fabrication.
