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

Future<void> pumpApp(WidgetTester tester) async {
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
  await pumpFrames(tester, frames: 6);
}

Future<void> switchToWitness(WidgetTester tester) async {
  await tester.tap(find.text('You'));
  await pumpFrames(tester);
  await tester.ensureVisible(find.text('Witness'));
  await pumpFrames(tester, frames: 3);
  await tester.tap(find.text('Witness'));
  await pumpFrames(tester);
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  Future<void> useSmallPhone(WidgetTester tester) async {
    // 360 x 800 logical pixels — the narrow end of supported Android phones.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('owner screens fit a 360dp phone', (tester) async {
    await useSmallPhone(tester);
    await pumpApp(tester);

    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('History'));
    await pumpFrames(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('You'));
    await pumpFrames(tester);
    expect(find.text('Demo preview'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('witness screens fit a 360dp phone', (tester) async {
    await useSmallPhone(tester);
    await pumpApp(tester);
    await switchToWitness(tester);

    await tester.tap(find.text('Today'));
    await pumpFrames(tester);
    expect(find.text('Mark today'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Mark today'));
    await pumpFrames(tester, frames: 3);
    await tester.tap(find.text('Mark today'));
    await pumpFrames(tester, frames: 5);
    expect(find.text('How did it go?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('schedule screen fits a 360dp phone', (tester) async {
    await useSmallPhone(tester);
    await pumpApp(tester);
    await switchToWitness(tester);

    final rhythm = find.textContaining('Every day');
    await tester.scrollUntilVisible(
      rhythm,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await pumpFrames(tester, frames: 3);
    await tester.tap(rhythm);
    await pumpFrames(tester, frames: 5);

    expect(find.textContaining('rhythm'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
