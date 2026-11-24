# Visual review: rendering screens so an agent can see them

Half of UI_CRAFT_STANDARD can only be judged by looking: whether one element dominates, whether the spacing has rhythm, whether dark mode holds together, whether 200% text breaks the layout. FLS-13 therefore marks any such judgement made from code as `unverified`. This file is the missing half: a proven way for any agent to **produce** images of every changed screen, and the protocol for **reviewing** them.

Read by `@flutter-test render`, `@flutter-implementation` (the polish pass, UI_CRAFT §8), `@flutter-verify` D15 and FLS-13.

---

## Why widget-test renders, not goldens or a device

| Option | Problem for an agent |
|--------|---------------------|
| Run the app on a device or emulator | Needs a display or a device the agent usually does not have, and screenshots are a manual step |
| Golden files (`matchesGoldenFile`) | Built for regression, not review. They are committed, platform-sensitive, and **render text in a placeholder font where every glyph is a box** unless fonts are loaded |
| **Widget-test render to PNG** | Headless, runs wherever `flutter test` runs, deterministic sizes, any theme and text scale, nothing committed |

**The font trap.** Under `flutter test` every glyph is drawn as a solid box until real fonts are loaded, and icons are glyphs too. A model shown that image will still describe a layout: it reviews rectangles and reports a pass. The helper below loads the app's own fonts and the SDK's Roboto and Material Icons. (The first review of `ui-recipes.md` caught exactly this: text was real, every icon was a hollow square, and all 17 widget and guideline tests still passed.) A review image that shows boxes instead of letters is invalid; say so, and do not review it.

---

## The helper (`test/support/visual_review.dart`)

Proven on the current stable SDK against `evals/apps/base`: the run passes, it writes six PNGs with real glyphs in light, dark and 200% variants, and the same render without `loadReviewFonts` shows boxes. Adjust the import to the project's UI library (`material_ui` or `package:flutter/material.dart`; see ARCHITECTURE_STANDARD).

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// One review variant: a window size, a brightness and a text scale.
class ReviewVariant {
  const ReviewVariant(this.name, this.size, this.brightness, this.textScale);

  final String name;
  final Size size;
  final Brightness brightness;
  final double textScale;
}

/// The three window size classes, both brightnesses, text at 100% and 200%.
/// Sizes sit inside the classes in THEMING/DESKTOP breakpoints (<600, 600-839,
/// >=840); use the project's own breakpoint tokens where they differ.
const reviewMatrix = <ReviewVariant>[
  ReviewVariant('compact-light', Size(390, 844), Brightness.light, 1),
  ReviewVariant('compact-dark', Size(390, 844), Brightness.dark, 1),
  ReviewVariant('compact-light-text200', Size(390, 844), Brightness.light, 2),
  ReviewVariant('medium-light', Size(700, 1000), Brightness.light, 1),
  ReviewVariant('expanded-light', Size(1280, 800), Brightness.light, 1),
  ReviewVariant('expanded-dark', Size(1280, 800), Brightness.dark, 1),
];

bool _fontsLoaded = false;

/// Loads the app's fonts (FontManifest.json) plus the SDK's Roboto and Material
/// Icons, which the Material defaults use. Reads are synchronous on purpose: real async file
/// I/O never completes inside testWidgets' fake-async zone, and the test hangs.
Future<void> loadReviewFonts() async {
  if (_fontsLoaded) return;
  final manifest = await rootBundle.loadString('FontManifest.json');
  for (final family
      in (json.decode(manifest) as List).cast<Map<String, dynamic>>()) {
    final loader = FontLoader(family['family'] as String);
    for (final font in (family['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  final root = Platform.environment['FLUTTER_ROOT'];
  final dir = Directory('$root/bin/cache/artifacts/material_fonts');
  if (root != null && dir.existsSync()) {
    final roboto = FontLoader('Roboto');
    for (final file in dir.listSync().whereType<File>()) {
      final name = file.uri.pathSegments.last;
      if (RegExp(r'^Roboto-[A-Za-z]+\.ttf$').hasMatch(name)) {
        roboto.addFont(
            Future.value(ByteData.sublistView(file.readAsBytesSync())));
      }
    }
    await roboto.load();
    // Icons are a font too: without this, every Icon renders as a hollow box.
    final icons = File('${dir.path}/MaterialIcons-Regular.otf');
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
  }
  _fontsLoaded = true;
}

/// Pumps [screen] under every variant and writes one PNG per variant to
/// build/visual_review/<name>/<variant>.png. Review images, not goldens:
/// nothing is compared and nothing is committed (build/ is gitignored).
Future<List<String>> renderForReview(
  WidgetTester tester, {
  required String name,
  required Widget Function() screen,
  required ThemeData Function(Brightness) theme,
  List<ReviewVariant> variants = reviewMatrix,
}) async {
  await loadReviewFonts();
  final written = <String>[];
  final key = GlobalKey();
  for (final v in variants) {
    tester.view.physicalSize = v.size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MediaQuery(
          data: MediaQueryData(
            size: v.size,
            textScaler: TextScaler.linear(v.textScale),
            platformBrightness: v.brightness,
          ),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme(v.brightness),
            home: screen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final path = 'build/visual_review/$name/${v.name}.png';
    await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File(path)..createSync(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
    written.add(path);
  }
  return written;
}
```

## A review test per screen and state

```dart
@Tags(['visual-review'])
library;

import 'package:flutter_test/flutter_test.dart';
// import the screen, the app theme and the same fakes the widget tests use

import '../support/visual_review.dart';

void main() {
  testWidgets('orders screen, error state, renders for review', (tester) async {
    final files = await renderForReview(
      tester,
      name: 'orders_error',
      screen: () => OrdersScreen(viewModel: FakeOrdersViewModel.error()),
      theme: (b) => b == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
    );
    expect(files, hasLength(reviewMatrix.length));
  });
}
```

Render **every state the SPEC defines** (FEATURE_SPEC §6), not just the data state: the empty and error states are where cheap UI hides. Use the fakes the widget tests already use; never a real network. Declare the tag in `dart_test.yaml` (`tags: {visual-review: {}}`) and run just the renders with `flutter test --tags visual-review`.

---

## The review protocol

1. **Validate the image first.** Letters and icons, not boxes. The right size. No red error screen (a render that throws produces Flutter's error widget, and that is a finding in itself).
2. **Answer the FLS-13 look questions from the image, one variant at a time:**

| Look for | In | Finding when |
|----------|----|-------------|
| One dominant element, matching SPEC §5 | `compact-light` | The eye lands somewhere else first, or nowhere |
| Accent appears only on the primary action | every variant | Accent on a badge, link or chart as well |
| Spacing rhythm | `compact-light`, `expanded-light` | Uneven gaps between peer items; borders doing spacing's job |
| Expanded layout uses the space | `expanded-*` | A phone column stretched across 1280 px; full-width text fields |
| Dark mode is designed | `*-dark` | Muddy greys, invisible dividers, a logo that vanishes, pure black |
| 200% text | `compact-light-text200` | Clipped or overlapping text, overflow stripes, truncated primary content |
| State copy | error and empty renders | Jargon, codes, no recovery action, an empty screen that does not teach |

3. **Report what you saw, with the file path.** "`build/visual_review/orders_error/compact-dark.png`: retry button and body text share the accent." A finding without the image path is a finding nobody can check.
4. **Measure what the eye can only estimate.** A hierarchy ratio or a contrast value comes from the theme roles or `textContrastGuideline`, not from squinting at pixels.

**An agent that cannot view images** still generates the renders, so a human can look, and reports every look question as `unverified (no image input)`. It never answers them from the code. Code-judged hierarchy is the exact failure this file exists to prevent.

---

## What a render does not prove

- **Platform look.** Tests render on the default test platform with Roboto. iOS typography (SF Pro) and Cupertino adaptivity need a simulator or device. Report them `not run` otherwise.
- **Motion, haptics, real images and real data.** Renders are settled frames of fake data.
- **Performance.** A smooth render says nothing about jank; that is `@flutter-perf`.
- **Screen-reader behaviour.** See ACCESSIBILITY_STANDARD §3.
