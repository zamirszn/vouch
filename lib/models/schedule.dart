/// The recurring day-pattern and reminder time chosen by the accountability
/// partner.
library;

enum ScheduleKind {
  daily,
  weekdays,
  weekends;

  String get id => name;

  String get label => switch (this) {
        ScheduleKind.daily => 'Every day',
        ScheduleKind.weekdays => 'Weekdays',
        ScheduleKind.weekends => 'Weekends',
      };

  String get shortLabel => switch (this) {
        ScheduleKind.daily => 'Daily',
        ScheduleKind.weekdays => 'Mon–Fri',
        ScheduleKind.weekends => 'Sat–Sun',
      };

  static ScheduleKind fromId(Object? value) {
    return ScheduleKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => ScheduleKind.daily,
    );
  }

  /// Whether this pattern includes [date]'s weekday (DateTime.weekday: Mon=1).
  bool includes(DateTime date) => switch (this) {
        ScheduleKind.daily => true,
        ScheduleKind.weekdays => date.weekday >= DateTime.monday &&
            date.weekday <= DateTime.friday,
        ScheduleKind.weekends => date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday,
      };

  String describe() => switch (this) {
        ScheduleKind.daily => 'A reminder every single day',
        ScheduleKind.weekdays => 'Monday through Friday',
        ScheduleKind.weekends => 'Saturday and Sunday',
      };
}

class VouchSchedule {
  const VouchSchedule({
    required this.kind,
    required this.hour,
    required this.minute,
    required this.timeZone,
  });

  final ScheduleKind kind;

  /// 24-hour clock, 0–23.
  final int hour;

  /// 0–59.
  final int minute;

  /// IANA identifier, e.g. `Africa/Lagos`.
  final String timeZone;

  bool isActiveOn(DateTime date) => kind.includes(date);

  String get clockLabel {
    final safeHour = hour % 24;
    final suffix = safeHour >= 12 ? 'PM' : 'AM';
    final displayHour = safeHour % 12 == 0 ? 12 : safeHour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  String get zoneLabel {
    final parts = timeZone.split('/');
    return parts.last.replaceAll('_', ' ');
  }

  String get summary => '${kind.label} · $clockLabel';

  VouchSchedule copyWith({
    ScheduleKind? kind,
    int? hour,
    int? minute,
    String? timeZone,
  }) {
    return VouchSchedule(
      kind: kind ?? this.kind,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      timeZone: timeZone ?? this.timeZone,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'kind': kind.name,
        'hour': hour,
        'minute': minute,
        'timeZone': timeZone,
      };

  static VouchSchedule? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final kind = ScheduleKind.fromId(map['kind']);
    final hour = map['hour'];
    final minute = map['minute'];
    final zone = map['timeZone'];
    if (hour is! int || minute is! int || zone is! String) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return VouchSchedule(
      kind: kind,
      hour: hour,
      minute: minute,
      timeZone: zone,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VouchSchedule &&
      other.kind == kind &&
      other.hour == hour &&
      other.minute == minute &&
      other.timeZone == timeZone;

  @override
  int get hashCode => Object.hash(kind, hour, minute, timeZone);

  @override
  String toString() => 'VouchSchedule(${kind.name} $hour:$minute $timeZone)';
}
