import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vouch/design/vouch_route.dart';
import 'package:vouch/screens/gallery_screen.dart';

Future<void> pumpFrames(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Widget harness({bool reducedMotion = false}) {
  return WidgetsApp(
    color: const Color(0xFF08090B),
    builder: (context, child) {
      final media = MediaQuery.of(context);
      return MediaQuery(
        data: reducedMotion
            ? media.copyWith(disableAnimations: true)
            : media,
        child: child ?? const SizedBox.shrink(),
      );
    },
    pageRouteBuilder: vouchPageRoute,
    home: const GalleryScreen(),
  );
}

void main() {
  testWidgets('gallery renders every component section', (tester) async {
    tester.view.physicalSize = const Size(1236, 2745);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness());
    await pumpFrames(tester);

    expect(find.text('The kit.'), findsOneWidget);
    for (final section in <String>[
      'tones',
      'type',
      'colour',
      'numbers',
      'buttons',
      'field',
      'sheets',
      'glyphs',
    ]) {
      await tester.scrollUntilVisible(
        find.text(section.toUpperCase()),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(section.toUpperCase()), findsOneWidget);
    }
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('gallery renders with reduced motion', (tester) async {
    tester.view.physicalSize = const Size(1236, 2745);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness(reducedMotion: true));
    await pumpFrames(tester);

    expect(find.text('The kit.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('signal button fires and toasts', (tester) async {
    tester.view.physicalSize = const Size(1236, 2745);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(harness());
    await pumpFrames(tester);

    await tester.ensureVisible(find.text('Signal'));
    await tester.tap(find.text('Signal'));
    await pumpFrames(tester);
    expect(find.text('Signal pressed.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
