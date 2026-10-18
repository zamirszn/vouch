/// A single promise shared by one owner and one accountability partner.
library;

import 'schedule.dart';

enum TrackStatus {
  waiting,
  active,
  paused,
  ended;

  String get id => name;

  static TrackStatus fromId(Object? value) {
    return TrackStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TrackStatus.waiting,
    );
  }

  String get label => switch (this) {
        TrackStatus.waiting => 'Waiting for partner',
        TrackStatus.active => 'Active',
        TrackStatus.paused => 'Paused',
        TrackStatus.ended => 'Ended',
      };
}

enum TrackRole {
  owner,
  partner,
  none;

  bool get isOwner => this == TrackRole.owner;
  bool get isPartner => this == TrackRole.partner;
  bool get isMember => this != TrackRole.none;
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

class Track {
  const Track({
    required this.id,
    required this.promise,
    required this.ownerUid,
    required this.ownerName,
    required this.inviteCode,
    required this.memberUids,
    this.promiseNote,
    this.ownerPhotoUrl,
    this.ownerPhone,
    this.partnerUid,
    this.partnerName,
    this.partnerPhotoUrl,
    this.partnerPhone,
    this.inviteExpiresAt,
    this.schedule,
    this.status = TrackStatus.waiting,
    this.startedAt,
    this.endedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String promise;
  final String? promiseNote;

  final String ownerUid;
  final String ownerName;
  final String? ownerPhotoUrl;
  final String? ownerPhone;

  final String? partnerUid;
  final String? partnerName;
  final String? partnerPhotoUrl;
  final String? partnerPhone;

  final List<String> memberUids;
  final String inviteCode;
  final DateTime? inviteExpiresAt;
  final VouchSchedule? schedule;
  final TrackStatus status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasPartner => partnerUid != null && partnerUid!.isNotEmpty;
  bool get isEnded => status == TrackStatus.ended;
  bool get isActive => status == TrackStatus.active;
  bool get hasSchedule => schedule != null;
  bool get isLive => status == TrackStatus.active && hasPartner && hasSchedule;

  String get ownerFirstName => ownerName.trim().split(RegExp(r'\s+')).first;
  String get partnerFirstName {
    final name = partnerName?.trim();
    if (name == null || name.isEmpty) return 'your partner';
    return name.split(RegExp(r'\s+')).first;
  }

  TrackRole roleFor(String? uid) {
    if (uid == null) return TrackRole.none;
    if (uid == ownerUid) return TrackRole.owner;
    if (uid == partnerUid) return TrackRole.partner;
    return TrackRole.none;
  }

  String? nameForRole(TrackRole role) => switch (role) {
        TrackRole.owner => ownerName,
        TrackRole.partner => partnerName,
        TrackRole.none => null,
      };

  bool inviteIsLive(DateTime now) =>
      inviteExpiresAt == null || inviteExpiresAt!.isAfter(now);

  factory Track.fromMap(String id, Map<String, dynamic> map) {
    final members = (map['memberUids'] as List?)?.whereType<String>().toList() ??
        const <String>[];
    return Track(
      id: id,
      promise: (map['promise'] as String?) ?? '',
      promiseNote: map['promiseNote'] as String?,
      ownerUid: (map['ownerUid'] as String?) ?? '',
      ownerName: (map['ownerName'] as String?) ?? 'Someone',
      ownerPhotoUrl: map['ownerPhotoUrl'] as String?,
      ownerPhone: map['ownerPhone'] as String?,
      partnerUid: map['partnerUid'] as String?,
      partnerName: map['partnerName'] as String?,
      partnerPhotoUrl: map['partnerPhotoUrl'] as String?,
      partnerPhone: map['partnerPhone'] as String?,
      memberUids: members,
      inviteCode: (map['inviteCode'] as String?) ?? '',
      inviteExpiresAt: _toDate(map['inviteExpiresAt']),
      schedule: VouchSchedule.fromMap(map['schedule']),
      status: TrackStatus.fromId(map['status']),
      startedAt: _toDate(map['startedAt']),
      endedAt: _toDate(map['endedAt']),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'promise': promise,
        'promiseNote': promiseNote,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhotoUrl': ownerPhotoUrl,
        'ownerPhone': ownerPhone,
        'partnerUid': partnerUid,
        'partnerName': partnerName,
        'partnerPhotoUrl': partnerPhotoUrl,
        'partnerPhone': partnerPhone,
        'memberUids': memberUids,
        'inviteCode': inviteCode,
        'inviteExpiresAt': inviteExpiresAt,
        'schedule': schedule?.toMap(),
        'status': status.name,
        'startedAt': startedAt,
        'endedAt': endedAt,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  Track copyWith({
    String? promise,
    String? promiseNote,
    String? ownerPhone,
    String? partnerUid,
    String? partnerName,
    String? partnerPhotoUrl,
    String? partnerPhone,
    List<String>? memberUids,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    VouchSchedule? schedule,
    TrackStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? updatedAt,
    bool clearPartner = false,
    bool clearSchedule = false,
  }) {
    return Track(
      id: id,
      promise: promise ?? this.promise,
      promiseNote: promiseNote ?? this.promiseNote,
      ownerUid: ownerUid,
      ownerName: ownerName,
      ownerPhotoUrl: ownerPhotoUrl,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      partnerUid: clearPartner ? null : (partnerUid ?? this.partnerUid),
      partnerName: clearPartner ? null : (partnerName ?? this.partnerName),
      partnerPhotoUrl:
          clearPartner ? null : (partnerPhotoUrl ?? this.partnerPhotoUrl),
      partnerPhone: clearPartner ? null : (partnerPhone ?? this.partnerPhone),
      memberUids: memberUids ?? this.memberUids,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteExpiresAt: inviteExpiresAt ?? this.inviteExpiresAt,
      schedule: clearSchedule ? null : (schedule ?? this.schedule),
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InvitePreview {
  const InvitePreview({
    required this.code,
    required this.trackId,
    required this.ownerUid,
    required this.promise,
    required this.ownerName,
    this.ownerPhotoUrl,
    this.expiresAt,
  });

  final String code;
  final String trackId;
  final String ownerUid;
  final String promise;
  final String ownerName;
  final String? ownerPhotoUrl;
  final DateTime? expiresAt;

  bool isExpired(DateTime now) =>
      expiresAt != null && !expiresAt!.isAfter(now);

  factory InvitePreview.fromMap(String code, Map<String, dynamic> map) {
    return InvitePreview(
      code: code,
      trackId: (map['trackId'] as String?) ?? '',
      ownerUid: (map['ownerUid'] as String?) ?? '',
      promise: (map['promise'] as String?) ?? '',
      ownerName: (map['ownerName'] as String?) ?? 'Someone',
      ownerPhotoUrl: map['ownerPhotoUrl'] as String?,
      expiresAt: _toDate(map['expiresAt']),
    );
  }
}
