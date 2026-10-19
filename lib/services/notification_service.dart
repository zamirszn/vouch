/// Local reminder scheduling in the track's timezone.
///
/// Free-tier design: both phones schedule the same wall-clock instant locally,
/// so they notify together without Cloud Functions. Occurrences are materialised
/// one by one for the next 60 days, which avoids weekly `matchDateTimeComponents`
/// DST ambiguity.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../models/track.dart';

class VouchNotificationStatus {
  const VouchNotificationStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
    required this.pendingCount,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsAllowed;
  final int pendingCount;

  bool get allGood => notificationsEnabled;
}

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'vouch_reminders';
  static const String _channelName = 'Daily promise reminders';
  static const String _channelDescription =
      'Reminders at the time your accountability partner chose.';

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<String> _taps = StreamController<String>.broadcast();

  bool _initialized = false;
  String _localTimeZone = 'UTC';

  Stream<String> get taps => _taps.stream;

  String get localTimeZone => _localTimeZone;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        _localTimeZone = info.identifier;
      } catch (_) {
        _localTimeZone = 'UTC';
      }
      try {
        tz.setLocalLocation(tz.getLocation(_localTimeZone));
      } catch (_) {
        _localTimeZone = 'UTC';
        tz.setLocalLocation(tz.UTC);
      }

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _taps.add(payload);
          }
        },
      );
      _initialized = true;
    } catch (error) {
      // A missing platform channel (widget tests, unsupported host) must never
      // break app startup. Notifications simply stay disabled.
      debugPrint('NotificationService.initialize failed: $error');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    return _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
  }

  Future<bool> _canScheduleExact() async {
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<VouchNotificationStatus> status() async {
    final android = _android;
    var enabled = true;
    var exact = true;
    var pending = 0;
    try {
      enabled = await android?.areNotificationsEnabled() ?? true;
      exact = await android?.canScheduleExactNotifications() ?? true;
      pending = (await _plugin.pendingNotificationRequests()).length;
    } catch (_) {
      // Tests / unsupported platforms.
    }
    return VouchNotificationStatus(
      notificationsEnabled: enabled,
      exactAlarmsAllowed: exact,
      pendingCount: pending,
    );
  }

  /// Requests the Android 13 notification permission and (when needed) the
  /// exact-alarm permission. Call from an in-app permission card, not at launch.
  Future<VouchNotificationStatus> requestPermissions() async {
    final android = _android;
    try {
      await android?.requestNotificationsPermission();
      if (!(await _canScheduleExact())) {
        await android?.requestExactAlarmsPermission();
      }
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
    }
    return status();
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAllPendingNotifications();
    } catch (error) {
      debugPrint('NotificationService.cancelAll failed: $error');
    }
  }

  /// Cancels every Vouch reminder and schedules the next 60 active days.
  ///
  /// The caller re-runs this on launch, resume, sign-in and whenever the track
  /// document changes, so schedule edits propagate on the next app open.
  Future<void> scheduleReminders({
    required Track track,
    required bool asPartner,
  }) async {
    await cancelAll();
    if (!track.isLive) return;
    final schedule = track.schedule;
    if (schedule == null) return;

    List<tz.TZDateTime> occurrences;
    try {
      occurrences = notificationOccurrences(
        schedule,
        count: VouchConfig.scheduledReminderDays,
      );
    } catch (error) {
      debugPrint('Notification occurrence generation failed: $error');
      return;
    }
    if (occurrences.isEmpty) return;

    final exact = await _canScheduleExact();
    final role = asPartner ? TrackRole.partner : TrackRole.owner;
    final owner = track.ownerFirstName;
    final title = asPartner
        ? 'Did $owner keep their promise?'
        : 'Your promise is waiting';
    final body = asPartner
        ? 'Time to check in with $owner, then mark today kept or missed.'
        : '${track.promise}. Tap to write what you did.';

    for (final occurrence in occurrences) {
      try {
        final zone = tz.getLocation(schedule.timeZone);
        final now = tz.TZDateTime.now(zone);
        if (!occurrence.isAfter(now)) continue;
        final day = dayKey(
          DateTime(occurrence.year, occurrence.month, occurrence.day),
        );
        await _plugin.zonedSchedule(
          id: _notificationId(occurrence, role),
          title: title,
          body: body,
          scheduledDate: occurrence,
          notificationDetails: _details(body),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'vouch://home/$day/${role.name}',
        );
      } catch (error) {
        // One bad occurrence (rare DST edge, OEM restriction) must not stop the
        // remaining reminders from being scheduled.
        debugPrint('Scheduling ${occurrence.toIso8601String()} failed: $error');
      }
    }
  }

  Future<void> showTest({required Track track, required bool asPartner}) async {
    final owner = track.ownerFirstName;
    final title =
        asPartner ? 'Did $owner keep their promise?' : 'Your promise is waiting';
    final body = asPartner
        ? 'Check in with $owner, then mark the day kept or missed.'
        : '${track.promise}. This is what a reminder looks like.';
    try {
      await _plugin.show(
        id: 900001,
        title: title,
        body: body,
        notificationDetails: _details(body),
        payload: 'vouch://home/today/${asPartner ? 'partner' : 'owner'}',
      );
    } catch (error) {
      debugPrint('Test notification failed: $error');
    }
  }

  NotificationDetails _details(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        icon: 'ic_notification',
        color: const Color(0xFF5B4BFF),
        styleInformation: BigTextStyleInformation(body),
        ticker: 'Vouch reminder',
      ),
    );
  }

  int _notificationId(tz.TZDateTime when, TrackRole role) {
    final date = when.year * 10000 + when.month * 100 + when.day;
    return date * 10 + (role == TrackRole.partner ? 1 : 0);
  }

  Future<void> dispose() async {
    await _taps.close();
  }
}
