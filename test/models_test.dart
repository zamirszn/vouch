import 'package:flutter_test/flutter_test.dart';
import 'package:vouch/models/day_entry.dart';
import 'package:vouch/models/schedule.dart';
import 'package:vouch/models/track.dart';
import 'package:vouch/models/user_profile.dart';

void main() {
  group('VouchSchedule', () {
    test('maps to and from Firestore', () {
      const schedule = VouchSchedule(
        kind: ScheduleKind.weekdays,
        hour: 7,
        minute: 5,
        timeZone: 'Africa/Lagos',
      );
      final restored = VouchSchedule.fromMap(schedule.toMap())!;

      expect(restored, schedule);
      expect(restored.kind, ScheduleKind.weekdays);
      expect(restored.summary, 'Weekdays · 7:05 AM');
      expect(restored.zoneLabel, 'Lagos');
    });

    test('rejects malformed maps', () {
      expect(
        VouchSchedule.fromMap(<String, dynamic>{
          'kind': 'daily',
          'hour': 24,
          'minute': 0,
          'timeZone': 'UTC',
        }),
        isNull,
      );
      expect(
        VouchSchedule.fromMap(<String, dynamic>{
          'kind': 'daily',
          'hour': 8,
          'minute': 60,
          'timeZone': 'UTC',
        }),
        isNull,
      );
      expect(
        VouchSchedule.fromMap(<String, dynamic>{
          'kind': 'daily',
          'hour': 8,
          'minute': 0,
        }),
        isNull,
      );
      expect(VouchSchedule.fromMap('nope'), isNull);
    });

    test('clock labels handle midnight and noon', () {
      const midnight = VouchSchedule(
        kind: ScheduleKind.daily,
        hour: 0,
        minute: 0,
        timeZone: 'UTC',
      );
      const noon = VouchSchedule(
        kind: ScheduleKind.daily,
        hour: 12,
        minute: 30,
        timeZone: 'UTC',
      );
      expect(midnight.clockLabel, '12:00 AM');
      expect(noon.clockLabel, '12:30 PM');
    });

    test('schedule patterns include the right weekdays', () {
      expect(ScheduleKind.daily.includes(DateTime(2026, 10, 18)), isTrue);
      expect(
        ScheduleKind.weekdays.includes(DateTime(2026, 10, 18)),
        isFalse,
      );
      expect(
        ScheduleKind.weekdays.includes(DateTime(2026, 10, 19)),
        isTrue,
      );
      expect(
        ScheduleKind.weekends.includes(DateTime(2026, 10, 17)),
        isTrue,
      );
    });
  });

  group('Track', () {
    final map = <String, dynamic>{
      'promise': 'Walk 30 minutes before sunset',
      'promiseNote': 'For my knees.',
      'ownerUid': 'owner-1',
      'ownerName': 'Zamir Smith',
      'ownerPhotoUrl': null,
      'ownerPhone': '+234 801 234 5678',
      'partnerUid': 'partner-1',
      'partnerName': 'Amara Okafor',
      'partnerPhone': '+234 808 765 4321',
      'memberUids': <String>['owner-1', 'partner-1'],
      'inviteCode': 'ABCD1234',
      'inviteExpiresAt': DateTime(2026, 10, 25),
      'schedule': <String, dynamic>{
        'kind': 'daily',
        'hour': 19,
        'minute': 30,
        'timeZone': 'Africa/Lagos',
      },
      'status': 'active',
      'startedAt': DateTime(2026, 9, 1),
      'createdAt': DateTime(2026, 9, 1),
      'updatedAt': DateTime(2026, 10, 18),
    };

    test('parses the canonical document', () {
      final track = Track.fromMap('track-1', map);

      expect(track.id, 'track-1');
      expect(track.hasPartner, isTrue);
      expect(track.isLive, isTrue);
      expect(track.ownerFirstName, 'Zamir');
      expect(track.partnerFirstName, 'Amara');
      expect(track.roleFor('owner-1'), TrackRole.owner);
      expect(track.roleFor('partner-1'), TrackRole.partner);
      expect(track.roleFor('stranger'), TrackRole.none);
      expect(track.schedule?.clockLabel, '7:30 PM');
      expect(track.inviteIsLive(DateTime(2026, 10, 20)), isTrue);
      expect(track.inviteIsLive(DateTime(2026, 10, 26)), isFalse);
    });

    test('is not live until partner and schedule exist', () {
      final waiting = Track.fromMap('track-1', <String, dynamic>{
        ...map,
        'partnerUid': null,
        'schedule': null,
        'status': 'waiting',
      });

      expect(waiting.hasPartner, isFalse);
      expect(waiting.hasSchedule, isFalse);
      expect(waiting.isLive, isFalse);
    });

    test('copyWith can clear the partner and schedule', () {
      final track = Track.fromMap('track-1', map);
      final cleared = track.copyWith(clearPartner: true, clearSchedule: true);

      expect(cleared.hasPartner, isFalse);
      expect(cleared.hasSchedule, isFalse);
      expect(cleared.memberUids, track.memberUids);
      expect(cleared.promise, track.promise);
    });
  });

  group('DayEntry', () {
    test('parses owner and partner fields', () {
      final entry = DayEntry.fromMap('2026-10-18', <String, dynamic>{
        'date': '2026-10-18',
        'note': 'Walked the canal.',
        'status': 'completed',
        'markedBy': 'partner-1',
        'markedAt': DateTime(2026, 10, 18, 20),
        'method': 'call',
        'partnerNote': 'Sounded convincing.',
      });

      expect(entry.hasNote, isTrue);
      expect(entry.isMarked, isTrue);
      expect(entry.isCompleted, isTrue);
      expect(entry.method, MarkMethod.call);
      expect(entry.toMap()['method'], 'call');
    });

    test('defaults to pending and can clear a mark', () {
      final pending = DayEntry.fromMap('2026-10-18', <String, dynamic>{});
      expect(pending.status, DayStatus.pending);
      expect(pending.isMarked, isFalse);

      final marked = pending.copyWith(
        status: DayStatus.missed,
        method: MarkMethod.inPerson,
        partnerNote: 'Did not happen.',
        markedAt: DateTime(2026, 10, 18),
      );
      final cleared = marked.copyWith(clearMark: true);

      expect(cleared.status, DayStatus.pending);
      expect(cleared.method, isNull);
      expect(cleared.partnerNote, isNull);
      expect(cleared.noteUpdatedAt, isNull);
    });
  });

  group('UserProfile', () {
    test('falls back to the email local part', () {
      final profile = UserProfile.fromMap('uid', <String, dynamic>{
        'email': 'zamir@example.com',
      });
      expect(profile.displayName, 'zamir');
    });

    test('uses Friend when nothing is known', () {
      final profile = UserProfile.fromMap('uid', <String, dynamic>{});
      expect(profile.displayName, 'Friend');
      expect(profile.initials, 'F');
    });
  });
}
