import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:vouch/core/date_utils.dart';
import 'package:vouch/models/day_entry.dart';
import 'package:vouch/models/schedule.dart';

void main() {
  late tz.Location lagos;

  setUpAll(() {
    tzdata.initializeTimeZones();
    lagos = tz.getLocation('Africa/Lagos');
  });

  group('day keys', () {
    test('round-trip a calendar day', () {
      final date = DateTime(2026, 10, 4);
      expect(dayKey(date), '2026-10-04');
      expect(parseDayKey('2026-10-04'), date);
    });

    test('dateAt crosses months and years', () {
      expect(dateAt(DateTime(2026, 12, 31), 1), DateTime(2027, 1, 1));
      expect(dateAt(DateTime(2026, 1, 1), -1), DateTime(2025, 12, 31));
    });

    test('malformed keys fall back rather than throwing', () {
      expect(parseDayKey('nope'), DateTime(1970));
    });
  });

  group('notificationOccurrences', () {
    test('daily schedule materialises one reminder per day', () {
      final from = tz.TZDateTime(lagos, 2026, 10, 18, 8);
      final days = notificationOccurrences(
        const VouchSchedule(
          kind: ScheduleKind.daily,
          hour: 19,
          minute: 30,
          timeZone: 'Africa/Lagos',
        ),
        count: 5,
        from: from,
      );

      expect(days, hasLength(5));
      expect(days.first, tz.TZDateTime(lagos, 2026, 10, 18, 19, 30));
      for (final day in days) {
        expect(day.hour, 19);
        expect(day.minute, 30);
        expect(day.isAfter(from), isTrue);
      }
      expect(
        days.last,
        tz.TZDateTime(lagos, 2026, 10, 22, 19, 30),
      );
    });

    test('a reminder that already passed today starts tomorrow', () {
      final from = tz.TZDateTime(lagos, 2026, 10, 18, 21);
      final days = notificationOccurrences(
        const VouchSchedule(
          kind: ScheduleKind.daily,
          hour: 19,
          minute: 30,
          timeZone: 'Africa/Lagos',
        ),
        count: 1,
        from: from,
      );

      expect(days.single, tz.TZDateTime(lagos, 2026, 10, 19, 19, 30));
    });

    test('weekday schedules skip weekends', () {
      final from = tz.TZDateTime(lagos, 2026, 10, 18, 8); // Sunday
      final days = notificationOccurrences(
        const VouchSchedule(
          kind: ScheduleKind.weekdays,
          hour: 7,
          minute: 0,
          timeZone: 'Africa/Lagos',
        ),
        count: 6,
        from: from,
      );

      expect(days, hasLength(6));
      for (final day in days) {
        expect(day.weekday, inInclusiveRange(1, 5));
      }
      expect(days.first, tz.TZDateTime(lagos, 2026, 10, 19, 7));
      expect(days[4], tz.TZDateTime(lagos, 2026, 10, 23, 7));
      expect(days[5], tz.TZDateTime(lagos, 2026, 10, 26, 7));
    });

    test('weekend schedules only include Saturday and Sunday', () {
      final from = tz.TZDateTime(lagos, 2026, 10, 18, 8); // Sunday
      final days = notificationOccurrences(
        const VouchSchedule(
          kind: ScheduleKind.weekends,
          hour: 9,
          minute: 15,
          timeZone: 'Africa/Lagos',
        ),
        count: 4,
        from: from,
      );

      expect(days, hasLength(4));
      expect(days[0], tz.TZDateTime(lagos, 2026, 10, 18, 9, 15));
      expect(days[1], tz.TZDateTime(lagos, 2026, 10, 24, 9, 15));
      for (final day in days) {
        expect(day.weekday, anyOf(DateTime.saturday, DateTime.sunday));
      }
    });
  });

  group('dayStateFor', () {
    const schedule = VouchSchedule(
      kind: ScheduleKind.daily,
      hour: 19,
      minute: 30,
      timeZone: 'Africa/Lagos',
    );
    final today = DateTime(2026, 10, 18);

    test('rest days follow the schedule pattern', () {
      const weekends = VouchSchedule(
        kind: ScheduleKind.weekends,
        hour: 9,
        minute: 0,
        timeZone: 'Africa/Lagos',
      );
      expect(
        dayStateFor(
          schedule: weekends,
          entry: null,
          date: DateTime(2026, 10, 14),
          today: today,
        ),
        VouchDayState.rest,
      );
    });

    test('marks win over the calendar', () {
      expect(
        dayStateFor(
          schedule: schedule,
          entry: const DayEntry(
            date: '2026-10-10',
            status: DayStatus.completed,
          ),
          date: DateTime(2026, 10, 10),
          today: today,
        ),
        VouchDayState.completed,
      );
      expect(
        dayStateFor(
          schedule: schedule,
          entry: const DayEntry(
            date: '2026-10-10',
            status: DayStatus.missed,
          ),
          date: DateTime(2026, 10, 10),
          today: today,
        ),
        VouchDayState.missed,
      );
    });

    test('unmarked past, today and future differ', () {
      expect(
        dayStateFor(
          schedule: schedule,
          entry: null,
          date: DateTime(2026, 10, 17),
          today: today,
        ),
        VouchDayState.missed,
      );
      expect(
        dayStateFor(
          schedule: schedule,
          entry: null,
          date: today,
          today: today,
        ),
        VouchDayState.pending,
      );
      expect(
        dayStateFor(
          schedule: schedule,
          entry: null,
          date: DateTime(2026, 10, 19),
          today: today,
        ),
        VouchDayState.upcoming,
      );
    });
  });

  group('computeStats', () {
    const schedule = VouchSchedule(
      kind: ScheduleKind.daily,
      hour: 19,
      minute: 30,
      timeZone: 'Africa/Lagos',
    );
    final day = dayKey;

    test('counts streaks, misses and completion rate', () {
      final days = <String, DayEntry>{
        day(DateTime(2026, 10, 12)): const DayEntry(
          date: '2026-10-12',
          status: DayStatus.completed,
        ),
        day(DateTime(2026, 10, 13)): const DayEntry(
          date: '2026-10-13',
          status: DayStatus.completed,
        ),
        day(DateTime(2026, 10, 14)): const DayEntry(
          date: '2026-10-14',
          status: DayStatus.completed,
        ),
        day(DateTime(2026, 10, 15)): const DayEntry(
          date: '2026-10-15',
          status: DayStatus.missed,
        ),
        day(DateTime(2026, 10, 16)): const DayEntry(
          date: '2026-10-16',
          status: DayStatus.completed,
        ),
      };

      final stats = computeStats(
        schedule: schedule,
        startedAt: DateTime(2026, 10, 12),
        today: DateTime(2026, 10, 18),
        days: days,
      );

      expect(stats.completed, 4);
      expect(stats.elapsed, 6);
      expect(stats.missed, 2);
      expect(stats.currentStreak, 0);
      expect(stats.bestStreak, 3);
      expect(stats.completionPercent, 67);
    });

    test('an unmarked today does not break the streak', () {
      final stats = computeStats(
        schedule: schedule,
        startedAt: DateTime(2026, 10, 14),
        today: DateTime(2026, 10, 16),
        days: <String, DayEntry>{
          day(DateTime(2026, 10, 14)): const DayEntry(
            date: '2026-10-14',
            status: DayStatus.completed,
          ),
          day(DateTime(2026, 10, 15)): const DayEntry(
            date: '2026-10-15',
            status: DayStatus.completed,
          ),
        },
      );

      expect(stats.currentStreak, 2);
      expect(stats.bestStreak, 2);
      expect(stats.elapsed, 2);
      expect(stats.completionRate, 1);
    });

    test('rest days are not counted as elapsed', () {
      const weekends = VouchSchedule(
        kind: ScheduleKind.weekends,
        hour: 9,
        minute: 0,
        timeZone: 'Africa/Lagos',
      );
      final stats = computeStats(
        schedule: weekends,
        startedAt: DateTime(2026, 10, 3), // Saturday
        today: DateTime(2026, 10, 18), // Sunday
        days: <String, DayEntry>{
          day(DateTime(2026, 10, 3)): const DayEntry(
            date: '2026-10-03',
            status: DayStatus.completed,
          ),
          day(DateTime(2026, 10, 4)): const DayEntry(
            date: '2026-10-04',
            status: DayStatus.completed,
          ),
          day(DateTime(2026, 10, 10)): const DayEntry(
            date: '2026-10-10',
            status: DayStatus.missed,
          ),
          day(DateTime(2026, 10, 11)): const DayEntry(
            date: '2026-10-11',
            status: DayStatus.completed,
          ),
          day(DateTime(2026, 10, 17)): const DayEntry(
            date: '2026-10-17',
            status: DayStatus.completed,
          ),
        },
      );

      // Active days: Oct 3, 4, 10, 11, 17; today (18) is still open.
      expect(stats.elapsed, 5);
      expect(stats.completed, 4);
      expect(stats.missed, 1);
      expect(stats.currentStreak, 2); // 11th and 17th, with rest days between
    });
  });

  test('countdown labels stay readable', () {
    expect(countdownLabel(const Duration(seconds: 30)), 'in under a minute');
    expect(countdownLabel(const Duration(minutes: 5)), 'in 5 min');
    expect(countdownLabel(const Duration(hours: 2, minutes: 4)), 'in 2 h 04 m');
    expect(countdownLabel(const Duration(days: 2, hours: 3)), 'in 2 d 3 h');
    expect(countdownLabel(const Duration(seconds: -1)), 'now');
  });
}
