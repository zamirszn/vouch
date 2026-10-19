import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:vouch/app.dart';
import 'package:vouch/components/vouch_icon.dart';
import 'package:vouch/models/track.dart';
import 'package:vouch/services/contact_service.dart';
import 'package:vouch/services/demo_repository.dart';
import 'package:vouch/services/notification_service.dart';
import 'package:vouch/state/auth_controller.dart';
import 'package:vouch/state/theme_controller.dart';
import 'package:vouch/state/track_controller.dart';

class _TestNotifications extends NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<VouchNotificationStatus> status() async {
    return const VouchNotificationStatus(
      notificationsEnabled: true,
      exactAlarmsAllowed: true,
      pendingCount: 60,
    );
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> scheduleReminders({
    required Track track,
    required bool asPartner,
  }) async {}

  @override
  Future<void> showTest({
    required Track track,
    required bool asPartner,
  }) async {}
}

Future<void> pumpFrames(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('all screens render without overflow', (tester) async {
    tester.view.physicalSize = const Size(1236, 2745);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = DemoTrackRepository();
    final notifications = _TestNotifications();
    final auth = AuthController(null, repository, demoMode: true);
    final tracks = TrackController(repository, notifications, auth);
    await auth.start();
    await tracks.start();

    await tester.pumpWidget(
      VouchApp(
        auth: auth,
        tracks: tracks,
        theme: ThemeController(),
        notifications: notifications,
        contact: const ContactService(),
      ),
    );
    await pumpFrames(tester);

    // Owner note editor sheet.
    await tester.ensureVisible(find.text('Edit'));
    await pumpFrames(tester, frames: 3);
    await tester.tap(find.text('Edit'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('What did you do today?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.text('What did you do today?'))).pop();
    await pumpFrames(tester);

    // History calendar and the day-detail sheet.
    await tester.tap(find.text('History'));
    await pumpFrames(tester);
    await tester.ensureVisible(find.textContaining('Walked the canal loop'));
    await pumpFrames(tester, frames: 3);
    await tester.tap(find.textContaining('Walked the canal loop'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('What you did'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.text('What you did'))).pop();
    await pumpFrames(tester);

    await tester.tap(find.text('You'));
    await pumpFrames(tester);

    await tester.ensureVisible(find.text('Witness'));
    await pumpFrames(tester, frames: 3);
    await tester.tap(find.text('Witness'));
    await pumpFrames(tester);

    await tester.ensureVisible(find.textContaining('Every day'));
    await pumpFrames(tester, frames: 3);
    await tester.tap(find.textContaining('Every day'));
    await pumpFrames(tester);

    expect(find.text('Which days?'), findsOneWidget);
    expect(find.text('What time?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is VouchIcon && widget.glyph == VouchGlyph.close,
      ),
    );
    await pumpFrames(tester);

    await tester.tap(find.text('Today'));
    await pumpFrames(tester);
    await tester.tap(find.text('Mark today'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('How did it go?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
