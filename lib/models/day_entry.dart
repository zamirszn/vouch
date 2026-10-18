/// One calendar day in a track.
library;

enum DayStatus {
  pending,
  completed,
  missed;

  String get id => name;

  static DayStatus fromId(Object? value) {
    return DayStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => DayStatus.pending,
    );
  }

  String get label => switch (this) {
        DayStatus.pending => 'Waiting',
        DayStatus.completed => 'Kept',
        DayStatus.missed => 'Missed',
      };
}

enum MarkMethod {
  inPerson,
  call,
  message,
  other;

  String get id => name;

  static MarkMethod? fromId(Object? value) {
    if (value is! String) return null;
    for (final method in MarkMethod.values) {
      if (method.name == value) return method;
    }
    return null;
  }

  String get label => switch (this) {
        MarkMethod.inPerson => 'In person',
        MarkMethod.call => 'Phone call',
        MarkMethod.message => 'Message',
        MarkMethod.other => 'Other',
      };

  String get shortLabel => switch (this) {
        MarkMethod.inPerson => 'In person',
        MarkMethod.call => 'Call',
        MarkMethod.message => 'Message',
        MarkMethod.other => 'Other',
      };
}

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  try {
    final dynamic dynamicValue = value;
    final result = dynamicValue.toDate();
    if (result is DateTime) return result;
  } catch (_) {
    // Not a Firestore Timestamp.
  }
  return null;
}

class DayEntry {
  const DayEntry({
    required this.date,
    this.note,
    this.noteUpdatedAt,
    this.status = DayStatus.pending,
    this.markedBy,
    this.markedAt,
    this.method,
    this.partnerNote,
  });

  /// `yyyy-MM-dd` — also the Firestore document id.
  final String date;

  /// What the promise-owner did that day.
  final String? note;
  final DateTime? noteUpdatedAt;

  final DayStatus status;
  final String? markedBy;
  final DateTime? markedAt;
  final MarkMethod? method;
  final String? partnerNote;

  bool get hasNote => (note?.trim().isNotEmpty ?? false);
  bool get isMarked => status != DayStatus.pending;
  bool get isCompleted => status == DayStatus.completed;

  factory DayEntry.fromMap(String id, Map<String, dynamic> map) {
    return DayEntry(
      date: (map['date'] as String?) ?? id,
      note: map['note'] as String?,
      noteUpdatedAt: _toDate(map['noteUpdatedAt']),
      status: DayStatus.fromId(map['status']),
      markedBy: map['markedBy'] as String?,
      markedAt: _toDate(map['markedAt']),
      method: MarkMethod.fromId(map['method']),
      partnerNote: map['partnerNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'date': date,
        if (note != null) 'note': note,
        if (noteUpdatedAt != null) 'noteUpdatedAt': noteUpdatedAt,
        'status': status.name,
        if (markedBy != null) 'markedBy': markedBy,
        if (markedAt != null) 'markedAt': markedAt,
        if (method != null) 'method': method!.name,
        if (partnerNote != null) 'partnerNote': partnerNote,
      };

  DayEntry copyWith({
    String? note,
    DateTime? noteUpdatedAt,
    DayStatus? status,
    String? markedBy,
    DateTime? markedAt,
    MarkMethod? method,
    String? partnerNote,
    bool clearMark = false,
  }) {
    return DayEntry(
      date: date,
      note: note ?? this.note,
      noteUpdatedAt: noteUpdatedAt ?? this.noteUpdatedAt,
      status: clearMark ? DayStatus.pending : (status ?? this.status),
      markedBy: clearMark ? null : (markedBy ?? this.markedBy),
      markedAt: clearMark ? null : (markedAt ?? this.markedAt),
      method: clearMark ? null : (method ?? this.method),
      partnerNote: clearMark ? null : (partnerNote ?? this.partnerNote),
    );
  }
}
