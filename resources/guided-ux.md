# Guided UX: evidence, Flutter building blocks and verified recipes

The binding rules are in [`GUIDED_UX_STANDARD`](../standards/20261124-GUIDED_UX_STANDARD.md); the workflow is [`@flutter-guidance`](../skills/flutter-guidance/skill.md). This file holds the evidence behind the rules, the Flutter mechanics, and two recipes (a wizard and a contextual tip) proven against the current stable SDK.

---

## 1. Evidence (read 2026-11-24)

| Source | Finding used |
|--------|--------------|
| [NN/g, *Mobile Tutorials: Wasted Effort or Efficiency Boost?*](https://www.nngroup.com/articles/mobile-tutorials/) | 70 participants, 4 iOS apps, deck-of-cards tutorials. Task success 91% (tutorial) against 94% (skipped), not significant; completion time not significantly different; ease **4.92 against 5.49**, significant (p = 0.047). "Think twice about creating a tutorial for simple applications"; prefer interactive, contextual help |
| [NN/g, *Onboarding Tutorials vs. Contextual Help*](https://www.nngroup.com/articles/onboarding-tutorials/) | Push revelations (out of context, intrusive) against pull revelations (triggered by a signal the user needs it now). Make help easy to dismiss **and to recall**; progressive disclosure; no memorisation; skip the obvious; understand the user's journey to the feature |
| [NN/g, *Instructional Overlays and Coach Marks*](https://www.nngroup.com/articles/mobile-instructional-overlay/) | One interaction per tip; one at a time at the right moment; chains of hints are dismissed faster and make the app look complicated; hints must look clearly different from interactive elements |
| [NN/g, *Wizards: Definition and Design Recommendations*](https://www.nngroup.com/articles/wizards/) | For novice users or infrequent processes; show the steps and the current one; enforce order; descriptive step labels ("Next" has weak information scent); allow exit and resume; self-sufficient steps; help beside, not over; reuse previous answers as defaults. Costs: more clicks, not gracefully interruptible, blocks the rest of the app |
| [GOV.UK, *Question pages*](https://design-system.service.gov.uk/patterns/question-pages/) | One question per page; always a back link that restores the previous page as left; heading about the current question; progress such as "Question 3 of 9" only if the total is reliable |
| [GOV.UK, *Check answers*](https://design-system.service.gov.uk/patterns/check-answers/) | A review page before confirmation; a Change link per answer that returns to the review afterwards; skipped optional answers shown as "Not provided"; say the transaction is not complete until confirmed; the submit button names the action |
| [W3C WAI, *Multi-page forms*](https://www.w3.org/WAI/tutorials/forms/multi-page/) | Progress in the title and heading ("Step 2 of 4: Shipping address"); the first step says how many follow; a step indicator marks completed and current steps; avoid time limits or let users extend them |
| [Apple HIG, *Onboarding*](https://developer.apple.com/design/human-interface-guidelines/onboarding) | Teach through interactivity; prefer context-specific tips placed near the relevant area; keep onboarding brief; make tutorials optional, do not show them again after a skip, keep them findable; focus on the app, not the device; defer nonessential setup; request permissions when the function is first used; no rating or purchase prompts before the user has experienced the app |

**Conflict resolved:** GOV.UK labels its button "Continue", while NN/g warns that generic labels have weak scent. Both hold in this framework by naming the destination: "Continue to payment". On the final step the button names the action: "Place order".

**Not used:** community "three onboarding screens" rules attributed to Apple. They are not in the HIG text; the standard's `MAX_TOUR_STEPS` default is labelled a project heuristic for that reason.

---

## 2. Flutter building blocks (confirmed in the installed SDK)

| Need | Use | Note |
|------|-----|------|
| Anchor a tip to a widget | `OverlayPortal` + `CompositedTransformTarget` / `CompositedTransformFollower` | Built in; follows the target when it scrolls or the window resizes |
| Announce a step or tip | `Semantics(liveRegion: true)` (implicit) | `SemanticsService.announce` is deprecated; `sendAnnouncement(View.of(context), …)` needs `package:flutter/semantics.dart`. Android has deprecated explicit announcement events, so prefer the live region |
| Mark the step heading | `Semantics(header: true)` | Screen-reader heading navigation lands on it |
| Back from a step | `PopScope(canPop:, onPopInvokedWithResult:)` | Not `WillPopScope` (breaks Android predictive back) |
| Progress | `LinearProgressIndicator(value:)` plus text | The text is what screen readers and users at a glance rely on |
| Survive process death | `RestorationMixin` or the state stack's persistence | The wizard index and answers, not just the widget |
| Material `Stepper` | Exists, but lays all steps out in one scrolling column or a horizontal header | Fine for short settings flows on wide windows. For mobile task flows the one-step-per-page layout below matches the research better |

**Packages for spotlight tours**, checked on pub.dev on 2026-11-24 (re-check before adding, per `packages-2026.md`): `showcaseview` (verified publisher simform.com, MIT, all six platforms, not discontinued) and `tutorial_coach_mark` (verified publisher rafaelbarbosatec.com, MIT, all six platforms, not discontinued). Use one only for rung-5 tours. The contextual tip below needs no package.

---

## 3. Recipe: wizard (`WizardController`, `WizardScaffold`, `ReviewAnswers`)

Uses the theme helpers from [`ui-recipes.md`](ui-recipes.md) §1 (`spacingOf`). The controller is a `ChangeNotifier`, so it fits any state stack; persist its index and the answers through the project's state layer for save-and-resume.

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

/// One step of a wizard. [title] names the step in the heading, in the step
/// counter's announcement and on the previous step's Continue button, so it
/// must say what the step is about ("Delivery address", not "Step 2").
class WizardStep {
  const WizardStep({required this.title, required this.builder});

  final String title;
  final WidgetBuilder builder;
}

/// Where the user is, owned outside the widget so the project's state stack
/// can persist it (save and resume, NN/g wizard guideline 5).
class WizardController extends ChangeNotifier {
  WizardController({required this.stepCount});

  final int stepCount;
  int _index = 0;
  int _furthest = 0;
  bool _returnToReview = false;

  int get index => _index;
  bool get isFirst => _index == 0;
  bool get isReview => _index == stepCount - 1;

  /// True while the user edits a step reached from the review step's Change
  /// link: Continue then goes straight back to the review (GOV.UK check answers).
  bool get returnsToReview => _returnToReview;

  void next() {
    _index =
        _returnToReview ? stepCount - 1 : (_index + 1).clamp(0, stepCount - 1);
    _returnToReview = false;
    if (_index > _furthest) _furthest = _index;
    notifyListeners();
  }

  void back() {
    if (isFirst) return;
    _index = _returnToReview ? stepCount - 1 : _index - 1;
    _returnToReview = false;
    notifyListeners();
  }

  /// Jumps to an earlier step. Never forward past what has been completed
  /// (NN/g wizard guideline 3: enforce the order).
  void edit(int step) {
    if (step > _furthest) return;
    _returnToReview = isReview;
    _index = step;
    notifyListeners();
  }
}

/// A wizard page: progress as text and bar, the step title as the page
/// heading (announced on change), Back that goes one step back rather than
/// out of the flow, and a primary button that names where it goes.
///
/// Strings are inline for readability; in a project they come from
/// AppLocalizations, with "Step n of m" as an intl message.
class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.flowTitle,
    required this.steps,
    required this.controller,
    required this.finishLabel,
    required this.onFinish,
    this.onSaveAndExit,
    this.canContinue = true,
  });

  final String flowTitle;
  final List<WizardStep> steps;
  final WizardController controller;

  /// The final action named by what it does: "Place order", never "Finish".
  final String finishLabel;
  final VoidCallback onFinish;
  final VoidCallback? onSaveAndExit;

  /// False while the current step is invalid. Validation messages belong in
  /// the step itself, next to the field (UI_CRAFT §6).
  final bool canContinue;

  /// One readable form column on wide windows.
  static const double maxContentWidth = 560;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final spacing = spacingOf(context);
        final i = controller.index;
        final step = steps[i];
        final String primaryLabel;
        if (controller.isReview) {
          primaryLabel = finishLabel;
        } else if (controller.returnsToReview) {
          primaryLabel = 'Save and return to review';
        } else {
          primaryLabel = 'Continue to ${steps[i + 1].title.toLowerCase()}';
        }
        return PopScope<Object?>(
          canPop: controller.isFirst,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) controller.back();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(flowTitle),
              leading: controller.isFirst
                  ? null
                  : BackButton(onPressed: controller.back),
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: (i + 1) / steps.length),
                  Expanded(
                    // Forms read best in one column: cap the width so fields
                    // and the primary button never stretch across a wide window.
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(spacing.lg),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Step ${i + 1} of ${steps.length}',
                                      style:
                                          theme.textTheme.labelLarge?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(height: spacing.xs),
                                    // A live region announces the new step to screen
                                    // readers when the title changes; header marks it as
                                    // the page heading for heading navigation.
                                    Semantics(
                                      header: true,
                                      liveRegion: true,
                                      label:
                                          'Step ${i + 1} of ${steps.length}: ${step.title}',
                                      child: ExcludeSemantics(
                                        child: Text(step.title,
                                            style:
                                                theme.textTheme.headlineLarge),
                                      ),
                                    ),
                                    SizedBox(height: spacing.lg),
                                    step.builder(context),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(spacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  FilledButton(
                                    onPressed: !canContinue
                                        ? null
                                        : controller.isReview
                                            ? onFinish
                                            : controller.next,
                                    child: Text(
                                      primaryLabel,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  // The secondary action sits under the primary
                                  // one, quieter and out of the app bar, which
                                  // it would crowd at large text sizes.
                                  if (onSaveAndExit != null)
                                    TextButton(
                                      onPressed: onSaveAndExit,
                                      child: const Text('Save and exit'),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One answer on the review ("check your answers") step.
class ReviewAnswer {
  const ReviewAnswer({required this.question, this.answer, required this.step});

  final String question;

  /// Null for a skipped optional question, shown as "Not provided".
  final String? answer;

  /// The step that asked it, for the Change link.
  final int step;
}

/// The review step: every answer, each with a Change link that returns here
/// after the edit, so nothing is re-entered.
class ReviewAnswers extends StatelessWidget {
  const ReviewAnswers(
      {super.key, required this.answers, required this.controller});

  final List<ReviewAnswer> answers;
  final WizardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = spacingOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Your order isn't placed until you confirm.",
          style: theme.textTheme.bodyLarge,
        ),
        SizedBox(height: spacing.md),
        for (final a in answers) ...[
          Card(
            child: ListTile(
              title: Text(a.question, style: theme.textTheme.labelLarge),
              subtitle: Text(
                a.answer ?? 'Not provided',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: a.answer == null
                      ? theme.colorScheme.onSurfaceVariant
                      : null,
                ),
              ),
              trailing: TextButton(
                onPressed: () => controller.edit(a.step),
                child: Semantics(
                  label: 'Change ${a.question.toLowerCase()}',
                  child: const ExcludeSemantics(child: Text('Change')),
                ),
              ),
            ),
          ),
          SizedBox(height: spacing.sm),
        ],
      ],
    );
  }
}
```

## 4. Recipe: contextual tip (`TipStore`, `TipCoordinator`, `FeatureTip`)

```dart
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';

/// Remembers which tips a user has dismissed. Bind it to the project's local
/// store (via the locked stack's DI); the in-memory version is for tests.
abstract interface class TipStore {
  bool hasSeen(String tipId);
  void markSeen(String tipId);
  void resetAll();
}

class InMemoryTipStore implements TipStore {
  final _seen = <String>{};

  @override
  bool hasSeen(String tipId) => _seen.contains(tipId);

  @override
  void markSeen(String tipId) => _seen.add(tipId);

  @override
  void resetAll() => _seen.clear();
}

/// Shows at most one tip at a time, and each tip at most once, until the user
/// asks to see tips again. Chains of tips are dismissed faster and make the app
/// look complicated (NN/g, instructional overlays).
class TipCoordinator extends ChangeNotifier {
  TipCoordinator(this._store);

  final TipStore _store;
  String? _active;

  String? get active => _active;

  /// Called when the user first reaches the feature the tip explains (a pull
  /// revelation), never at launch. Returns whether the tip is now showing.
  bool request(String tipId) {
    if (_active != null || _store.hasSeen(tipId)) return false;
    _active = tipId;
    notifyListeners();
    return true;
  }

  void dismiss() {
    final id = _active;
    if (id == null) return;
    _store.markSeen(id);
    _active = null;
    notifyListeners();
  }

  /// Behind "Show tips again" in Help or Settings, so dismissed help can be
  /// found again (NN/g: easy to dismiss and to recall; Apple HIG).
  void resetAll() {
    _store.resetAll();
    notifyListeners();
  }
}

/// Anchors a short tip under [child] when the coordinator says it is active.
/// Drawn on inverse surface colours so it reads as an annotation, not as a
/// control the user might try to tap (NN/g, instructional overlays).
class FeatureTip extends StatefulWidget {
  const FeatureTip({
    super.key,
    required this.tipId,
    required this.coordinator,
    required this.message,
    required this.child,
  });

  final String tipId;
  final TipCoordinator coordinator;

  /// One interaction, one sentence: "Swipe an order left to archive it."
  final String message;
  final Widget child;

  /// Keeps a tip to a short, readable line length.
  static const double maxWidth = 280;

  @override
  State<FeatureTip> createState() => _FeatureTipState();
}

class _FeatureTipState extends State<FeatureTip> {
  final _portal = OverlayPortalController();
  final _link = LayerLink();

  @override
  void initState() {
    super.initState();
    widget.coordinator.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    widget.coordinator.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    if (!mounted) return;
    final shouldShow = widget.coordinator.active == widget.tipId;
    if (shouldShow && !_portal.isShowing) _portal.show();
    if (!shouldShow && _portal.isShowing) _portal.hide();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) => CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomCenter,
          followerAnchor: Alignment.topCenter,
          child: Align(
            alignment: Alignment.topCenter,
            child: _TipBubble(
              message: widget.message,
              onDismiss: widget.coordinator.dismiss,
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _TipBubble extends StatelessWidget {
  const _TipBubble({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = spacingOf(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: spacing.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FeatureTip.maxWidth),
        child: Material(
          color: scheme.inverseSurface,
          elevation: 3,
          borderRadius: BorderRadius.circular(spacing.sm),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                spacing.md, spacing.md, spacing.sm, spacing.xs),
            child: Semantics(
              liveRegion: true,
              container: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onInverseSurface,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.inversePrimary,
                      ),
                      onPressed: onDismiss,
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Trigger the tip from the place the user first reaches the feature: for example, after the orders list shows data for the first time, call `coordinator.request('archive-swipe')`. Bind `TipStore` to local storage through the locked stack's DI, and put "Show tips again" (`coordinator.resetAll()`) in Help or Settings.

## 5. The tests that prove them

Behaviour, accessibility and review renders: 11 tests, all passing on 2026-11-24. Adapt them with the recipes.

```dart
import 'package:eval_app/core/theme/app_theme.dart';
import 'package:eval_app/guidance/feature_tip.dart';
import 'package:eval_app/guidance/wizard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../support/visual_review.dart';

Widget orderWizard(WizardController c, {VoidCallback? onFinish}) {
  return WizardScaffold(
    flowTitle: 'New order',
    controller: c,
    finishLabel: 'Place order',
    onFinish: onFinish ?? () {},
    onSaveAndExit: () {},
    steps: [
      WizardStep(
        title: 'Customer',
        builder: (_) => const TextField(
          decoration: InputDecoration(labelText: 'Customer name'),
        ),
      ),
      WizardStep(
        title: 'Delivery address',
        builder: (_) => const TextField(
          decoration: InputDecoration(labelText: 'Street and number'),
        ),
      ),
      WizardStep(
        title: 'Review your order',
        builder: (_) => ReviewAnswers(
          controller: c,
          answers: const [
            ReviewAnswer(question: 'Customer', answer: 'Alba Ruiz', step: 0),
            ReviewAnswer(
                question: 'Delivery address',
                answer: 'Calle Mayor 12',
                step: 1),
            ReviewAnswer(question: 'Delivery notes', step: 1),
          ],
        ),
      ),
    ],
  );
}

Widget app(Widget home, [Brightness b = Brightness.light]) => MaterialApp(
      theme: b == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      home: home,
    );

Widget tipped(TipCoordinator coordinator) => Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          FeatureTip(
            tipId: 'filter',
            coordinator: coordinator,
            message: 'Filter orders by status or date.',
            child: IconButton(
              tooltip: 'Filter',
              onPressed: () {},
              icon: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: Center(
        child: FeatureTip(
          tipId: 'archive',
          coordinator: coordinator,
          message: 'Swipe an order left to archive it.',
          child: const Text('Alba Ruiz  ·  1,240.00'),
        ),
      ),
    );

void main() {
  group('wizard', () {
    testWidgets('names the next step and counts progress', (tester) async {
      final c = WizardController(stepCount: 3);
      await tester.pumpWidget(app(orderWizard(c)));
      expect(find.text('Step 1 of 3'), findsOneWidget);
      expect(find.text('Continue to delivery address'), findsOneWidget);
      await tester.tap(find.text('Continue to delivery address'));
      await tester.pump();
      expect(find.text('Step 2 of 3'), findsOneWidget);
      expect(find.text('Continue to review your order'), findsOneWidget);
    });

    testWidgets('system back goes one step back, not out of the flow',
        (tester) async {
      final c = WizardController(stepCount: 3)..next();
      await tester.pumpWidget(app(orderWizard(c)));
      expect(c.index, 1);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(c.index, 0);
      expect(find.text('Step 1 of 3'), findsOneWidget);
    });

    testWidgets(
        'review: skipped answer says Not provided; Change returns to review',
        (tester) async {
      final c = WizardController(stepCount: 3)
        ..next()
        ..next();
      var placed = false;
      await tester
          .pumpWidget(app(orderWizard(c, onFinish: () => placed = true)));
      expect(find.text('Not provided'), findsOneWidget);
      await tester.tap(find.text('Change').first);
      await tester.pump();
      expect(c.index, 0);
      expect(find.text('Save and return to review'), findsOneWidget);
      await tester.tap(find.text('Save and return to review'));
      await tester.pump();
      expect(c.isReview, isTrue);
      await tester.tap(find.text('Place order'));
      expect(placed, isTrue);
    });

    testWidgets('cannot jump forward past the furthest completed step',
        (tester) async {
      final c = WizardController(stepCount: 3);
      c.edit(2);
      expect(c.index, 0);
    });

    for (final b in Brightness.values) {
      testWidgets('meets a11y guidelines (${b.name})', (tester) async {
        final handle = tester.ensureSemantics();
        final c = WizardController(stepCount: 3)
          ..next()
          ..next();
        await tester.pumpWidget(app(orderWizard(c), b));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });

  group('feature tip', () {
    testWidgets('shows once; one at a time; recallable', (tester) async {
      final store = InMemoryTipStore();
      final coordinator = TipCoordinator(store);
      await tester.pumpWidget(app(tipped(coordinator)));
      expect(coordinator.request('archive'), isTrue);
      expect(coordinator.request('filter'), isFalse, reason: 'one at a time');
      await tester.pump();
      expect(find.text('Swipe an order left to archive it.'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pump();
      expect(find.text('Swipe an order left to archive it.'), findsNothing);
      expect(coordinator.request('archive'), isFalse, reason: 'seen');
      expect(coordinator.request('filter'), isTrue);
      coordinator.dismiss();
      coordinator.resetAll();
      expect(coordinator.request('archive'), isTrue, reason: 'recallable');
    });

    for (final b in Brightness.values) {
      testWidgets('tip meets a11y guidelines (${b.name})', (tester) async {
        final handle = tester.ensureSemantics();
        final coordinator = TipCoordinator(InMemoryTipStore());
        await tester.pumpWidget(app(tipped(coordinator), b));
        coordinator.request('archive');
        await tester.pump();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });

  group('renders', () {
    testWidgets('wizard step and review', (tester) async {
      final c1 = WizardController(stepCount: 3)..next();
      await renderForReview(tester,
          name: 'wizard_step', screen: () => orderWizard(c1), theme: themeFor);
      final c2 = WizardController(stepCount: 3)
        ..next()
        ..next();
      await renderForReview(tester,
          name: 'wizard_review',
          screen: () => orderWizard(c2),
          theme: themeFor);
    });

    testWidgets('feature tip', (tester) async {
      final coordinator = TipCoordinator(InMemoryTipStore())
        ..request('archive');
      await renderForReview(tester,
          name: 'feature_tip',
          screen: () => tipped(coordinator),
          theme: themeFor);
    });
  });
}

ThemeData themeFor(Brightness b) =>
    b == Brightness.dark ? AppTheme.dark() : AppTheme.light();
```

---

## 6. What looking at the renders found

All 11 tests passed on the first green run, and the renders still showed three defects, each fixed above:

1. At expanded width the form fields and the "Place order" button stretched across 1280 px. Fixed by capping the wizard column at `maxContentWidth`.
2. The step heading was `headlineMedium`: 28 sp against a 16 sp body is 1.75×, under UI_CRAFT §3's 2× floor. It is now `headlineLarge` (2×).
3. At 200% text, "Save and exit" in the app bar truncated the flow title to "New or…". The secondary action moved under the primary button, where it is also correctly subordinate.

None of these can fail a widget test that does not know to look for them. That is why `visual-review.md` exists.
