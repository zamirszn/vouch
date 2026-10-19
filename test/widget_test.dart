import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:vouch/app.dart';
import 'package:vouch/models/track.dart';
import 'package:vouch/services/contact_service.dart';
import 'package:vouch/services/demo_repository.dart';
import 'package:vouch/services/notification_service.dart';
import 'package:vouch/state/auth_controller.dart';
import 'package:vouch/state/theme_controller.dart';
import 'package:vouch/state/track_controller.dart';

class _TestNotifications extends NotificationService {  @override
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

/// Pumps several frames so page transitions and spring entrances can finish
/// (the animated background never settles, so pumpAndSettle cannot be used).
Future<void> pumpFrames(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('demo mode renders the owner home and switches roles',
      (tester) async {
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

    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.textContaining('Walk 30 minutes'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Witnessed by Amara Okafor.'), findsOneWidget);
    expect(find.textContaining('Legs tired, head clear'), findsOneWidget);

    // Open Settings, switch to the witness side, then return to Today.
    await tester.tap(find.text('You'));
    await pumpFrames(tester);
    expect(find.text('Demo preview'), findsOneWidget);

    await tester.ensureVisible(find.text('Witness'));
    await pumpFrames(tester, frames: 3);
    await tester.tap(find.text('Witness'));
    await pumpFrames(tester);

    await tester.tap(find.text('Today'));
    await pumpFrames(tester);

    expect(find.textContaining('WITNESSING'), findsOneWidget);
    expect(find.text('Mark today'), findsOneWidget);
    expect(find.text('Witness, not judge.'), findsOneWidget);

    await tester.ensureVisible(find.text('Mark today'));
    await pumpFrames(tester, frames: 3);
    await tester.tap(find.text('Mark today'));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('How did it go?'), findsOneWidget);
    expect(find.text('Mark kept'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
