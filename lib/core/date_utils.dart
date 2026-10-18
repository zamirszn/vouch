/// Date, schedule-occurrence, streak and history helpers.
///
/// All day boundaries are evaluated in the **track's timezone** so both phones
/// agree on which day a promise belongs to and when a reminder fires.
library;

import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/day_entry.dart';
import '../models/schedule.dart';

enum VouchDayState { completed, missed, pending, rest, upcoming }

class TrackStats {
  const TrackStats({
    required this.currentStreak,
    required this.bestStreak,
    required this.completed,
    required this.elapsed,
    required this.missed,
  });

  static const TrackStats empty = TrackStats(
    currentStreak: 0,
    bestStreak: 0,
    completed: 0,
    elapsed: 0,
    missed: 0,
  );

  final int currentStreak;
  final int bestStreak;
  final int completed;
  final int elapsed;
  final int missed;

  double get completionRate => elapsed == 0 ? 0 : completed / elapsed;
  int get completionPercent => (completionRate * 100).round();
}

String dayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}

DateTime parseDayKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return DateTime(1970);
  return DateTime(
    int.tryParse(parts[0]) ?? 1970,
    int.tryParse(parts[1]) ?? 1,
    int.tryParse(parts[2]) ?? 1,
  );
}

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

/// Calendar arithmetic that is safe across month/year boundaries.
DateTime dateAt(DateTime base, int offset) =>
    DateTime(base.year, base.month, base.day + offset);

tz.Location locationFor(String? timeZone) {
  if (timeZone == null || timeZone.isEmpty) return tz.local;
  try {
    return tz.getLocation(timeZone);
  } catch (_) {
    return tz.local;
  }
}

tz.TZDateTime nowIn(String? timeZone) => tz.TZDateTime.now(locationFor(timeZone));

DateTime todayIn(String? timeZone) {
  final now = nowIn(timeZone);
  return DateTime(now.year, now.month, now.day);
}

/// The next [count] reminder instants (as absolute TZDateTimes) for a schedule.
///
/// One alarm is produced per active day rather than a repeating weekly alarm so
/// daylight-saving transitions stay correct.
List<tz.TZDateTime> notificationOccurrences(
  VouchSchedule schedule, {
  int count = 60,
  tz.TZDateTime? from,
}) {
  final location = locationFor(schedule.timeZone);
  final now = from ?? tz.TZDateTime.now(location);
  final occurrences = <tz.TZDateTime>[];
  // Scan far enough ahead that sparse patterns (weekends, with a weekday gap
  // of five days) still yield [count] reminders.
  final scanLimit = count * 7 + 7;
  for (var offset = 0; offset < scanLimit && occurrences.length < count; offset++) {
    final date = DateTime(now.year, now.month, now.day + offset);
    if (!schedule.isActiveOn(date)) continue;
    final occurrence = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      schedule.hour,
      schedule.minute,
    );
    // A one-minute grace keeps a reminder schedulable while the user taps save.
    if (occurrence.isAfter(now.add(const Duration(minutes: 1)))) {
      occurrences.add(occurrence);
    }
  }
  return occurrences;
}

DateTime? nextReminderAt(VouchSchedule? schedule) {
  if (schedule == null) return null;
  final occurrences = notificationOccurrences(schedule, count: 1);
  return occurrences.isEmpty ? null : occurrences.first;
}

VouchDayState dayStateFor({
  required VouchSchedule? schedule,
  required DayEntry? entry,
  required DateTime date,
  required DateTime today,
}) {
  if (schedule == null || !schedule.isActiveOn(date)) {
    return VouchDayState.rest;
  }
  if (entry?.status == DayStatus.completed) return VouchDayState.completed;
  if (entry?.status == DayStatus.missed) return VouchDayState.missed;
  final target = dateOnly(date);
  final now = dateOnly(today);
  if (target.isBefore(now)) return VouchDayState.missed;
  if (target.isAtSameMomentAs(now)) return VouchDayState.pending;
  return VouchDayState.upcoming;
}

TrackStats computeStats({
  required VouchSchedule? schedule,
  required DateTime? startedAt,
  required DateTime today,
  required Map<String, DayEntry> days,
}) {
  if (schedule == null || startedAt == null) return TrackStats.empty;

  final start = dateOnly(startedAt);
  final end = dateOnly(today);
  if (end.isBefore(start)) return TrackStats.empty;

  var bestStreak = 0;
  var running = 0;
  var completed = 0;
  var elapsed = 0;
  var missed = 0;

  final totalDays = end.difference(start).inDays;
  for (var offset = 0; offset <= totalDays; offset++) {
    final date = dateAt(start, offset);
    if (!schedule.isActiveOn(date)) continue;
    final entry = days[dayKey(date)];
    final isToday = dayKey(date) == dayKey(end);
    if (entry?.status == DayStatus.completed) {
      running++;
      completed++;
      elapsed++;
      if (running > bestStreak) bestStreak = running;
    } else if (isToday) {
      // The day is still open; it neither extends nor breaks the streak yet.
    } else {
      if (entry?.status == DayStatus.missed || entry == null) missed++;
      elapsed++;
      running = 0;
    }
  }

  var currentStreak = 0;
  for (var offset = 0; offset < 400; offset++) {
    final date = dateAt(end, -offset);
    if (date.isBefore(start)) break;
    if (!schedule.isActiveOn(date)) continue;
    final entry = days[dayKey(date)];
    if (entry?.status == DayStatus.completed) {
      currentStreak++;
      continue;
    }
    if (offset == 0 &&
        (entry == null || entry.status == DayStatus.pending)) {
      // Today is still open — don't punish the streak for it.
      continue;
    }
    break;
  }

  return TrackStats(
    currentStreak: currentStreak,
    bestStreak: bestStreak < currentStreak ? currentStreak : bestStreak,
    completed: completed,
    elapsed: elapsed,
    missed: missed,
  );
}

String friendlyDay(DateTime date, {DateTime? today}) {
  final now = dateOnly(today ?? DateTime.now());
  final target = dateOnly(date);
  if (target == now) return 'Today';
  if (target == dateAt(now, -1)) return 'Yesterday';
  if (target == dateAt(now, 1)) return 'Tomorrow';
  return DateFormat('EEE, d MMM').format(target);
}

String monthLabel(DateTime date) => DateFormat('MMMM yyyy').format(date);

String shortWeekday(DateTime date) => DateFormat('EEE').format(date);

String greetingForHour(int hour) {
  if (hour < 5) return 'Still up';
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String firstNameOf(String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'friend';
  return trimmed.split(RegExp(r'\s+')).first;
}

String countdownLabel(Duration duration) {
  if (duration.isNegative) return 'now';
  if (duration.inMinutes < 1) return 'in under a minute';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours >= 24) {
    final days = duration.inDays;
    final remHours = hours.remainder(24);
    return remHours == 0 ? 'in $days d' : 'in $days d $remHours h';
  }
  if (hours == 0) return 'in $minutes min';
  return 'in $hours h ${minutes.toString().padLeft(2, '0')} m';
}
