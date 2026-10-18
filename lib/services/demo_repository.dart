/// Fully offline, seeded repository used by `--dart-define=VOUCH_DEMO=true`.
///
/// It implements the same contract as the Firebase repository, so every screen
/// and controller runs unchanged. Mutations update in-memory state so marking,
/// notes, schedule changes and role switching can be exercised without an
/// account or network.
library;

import 'dart:async';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../models/day_entry.dart';
import '../models/schedule.dart';
import '../models/track.dart';
import '../models/user_profile.dart';
import 'track_repository.dart';

class DemoTrackRepository implements TrackRepository {
  DemoTrackRepository({
    this.timeZone = 'Africa/Lagos',
    DateTime? now,
  }) {
    _seed(now);
  }

  final String timeZone;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  late Track _track;
  final Map<String, DayEntry> _days = <String, DayEntry>{};
  final Map<String, UserProfile> _profiles = <String, UserProfile>{};
  bool _asPartner = false;

  static const List<String> _ownerNotes = <String>[
    'Walked the canal loop at sunset. Legs tired, head clear.',
    'Did 35 minutes around the estate. Phone said 4.1 km.',
    'Rushed one in before the rain. Still counts.',
    'Treadmill at the gym, then ten minutes of stretching.',
    'Walked with Mum. She talks faster than I walk.',
    'Slow one. Knees complaining, but I showed up.',
    'Sunset walk with a podcast. Forgot I was exercising.',
    'Two laps of the park. Saw the same dog twice.',
    'Late, but done. Streetlights and cold air.',
    'Short loop, deep breath. Better than nothing.',
    'Made it before dark this time.',
    'Full thirty. Even ran the last bit.',
  ];

  static const List<String> _partnerNotes = <String>[
    'Called after dinner — confirmed the walk. Sounded good.',
    'Voice note checks out, and the steps screenshot too.',
    'Met at the park briefly. Saw the loop happen.',
    'Texted and got a photo. Marking it kept.',
    'Walked together, actually. Counted it.',
    'Confirmed on the phone. Short but real.',
  ];

  void _seed(DateTime? seed) {
    // Anchor the demo to the calendar day the app will consider "today", so
    // the seeded entry keeps matching as the clock rolls over. An explicit
    // seed still wins for deterministic tests.
    final now = seed ?? nowIn(timeZone);
    final today = DateTime(now.year, now.month, now.day);
    final started = today.subtract(const Duration(days: 41));
    final schedule = VouchSchedule(
      kind: ScheduleKind.daily,
      hour: 19,
      minute: 30,
      timeZone: timeZone,
    );

    _profiles[DemoIds.owner] = UserProfile(
      uid: DemoIds.owner,
      displayName: 'Zamir',
      email: 'zamir@example.com',
      phone: '+234 801 234 5678',
      createdAt: started,
    );
    _profiles[DemoIds.partner] = UserProfile(
      uid: DemoIds.partner,
      displayName: 'Amara Okafor',
      email: 'amara@example.com',
      phone: '+234 808 765 4321',
      createdAt: started,
    );

    _track = Track(
      id: DemoIds.track,
      promise: 'Walk 30 minutes before sunset',
      promiseNote:
          'For my knees, my head, and the version of me that shows up tomorrow.',
      ownerUid: DemoIds.owner,
      ownerName: 'Zamir',
      ownerPhone: '+234 801 234 5678',
      partnerUid: DemoIds.partner,
      partnerName: 'Amara Okafor',
      partnerPhone: '+234 808 765 4321',
      memberUids: const <String>[DemoIds.owner, DemoIds.partner],
      inviteCode: 'DEMO2026',
      inviteExpiresAt: now.add(const Duration(days: 7)),
      schedule: schedule,
      status: TrackStatus.active,
      startedAt: started,
      createdAt: started,
      updatedAt: now,
    );

    const missedOffsets = <int>{37, 28, 19, 11, 4};
    const methods = <MarkMethod>[
      MarkMethod.call,
      MarkMethod.message,
      MarkMethod.inPerson,
    ];

    for (var offset = 41; offset >= 1; offset--) {
      final date = today.subtract(Duration(days: offset));
      final key = dayKey(date);
      final missed = missedOffsets.contains(offset);
      final method = methods[offset % methods.length];
      final hasNote = offset <= 12;

      _days[key] = DayEntry(
        date: key,
        note: hasNote ? _ownerNotes[12 - offset] : null,
        noteUpdatedAt:
            hasNote ? date.add(const Duration(hours: 19, minutes: 45)) : null,
        status: missed ? DayStatus.missed : DayStatus.completed,
        markedBy: DemoIds.partner,
        markedAt: date.add(const Duration(hours: 20)),
        method: method,
        partnerNote: missed
            ? 'No note and no answer. Marked missed.'
            : _partnerNotes[offset % _partnerNotes.length],
      );
    }

    final todayKey = dayKey(today);
    _days[todayKey] = DayEntry(
      date: todayKey,
      note: 'Walked the canal loop at sunset. Legs tired, head clear.',
      noteUpdatedAt: now.subtract(const Duration(hours: 2)),
      status: DayStatus.pending,
    );
  }

  Stream<T> _watch<T>(T Function() read) {
    late StreamController<T> controller;
    StreamSubscription<void>? subscription;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        subscription = _changes.stream.listen((_) {
          if (!controller.isClosed) controller.add(read());
        });
      },
      onCancel: () async {
        await subscription?.cancel();
        subscription = null;
      },
    );
    return controller.stream;
  }

  void _publish() {
    if (!_changes.isClosed) _changes.add(null);
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      _watch(() => _profiles[uid]);

  @override
  Future<UserProfile?> getProfile(String uid) async => _profiles[uid];

  @override
  Future<void> ensureProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
  }) async {
    final existing = _profiles[uid];
    if (existing == null) {
      _profiles[uid] = UserProfile(
        uid: uid,
        displayName: displayName ?? 'Friend',
        email: email ?? '',
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );
    } else {
      _profiles[uid] = existing.copyWith(
        displayName: displayName,
        email: email,
        photoUrl: photoUrl,
      );
    }
    _publish();
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? phone,
  }) async {
    final existing = _profiles[uid];
    if (existing == null) {
      _profiles[uid] = UserProfile(
        uid: uid,
        displayName: displayName ?? 'Friend',
        phone: phone,
        createdAt: DateTime.now(),
      );
    } else {
      _profiles[uid] = UserProfile(
        uid: uid,
        displayName: (displayName == null || displayName.trim().isEmpty)
            ? existing.displayName
            : displayName.trim(),
        email: existing.email,
        photoUrl: existing.photoUrl,
        phone: phone,
        createdAt: existing.createdAt,
      );
    }
    _publish();
  }

  @override
  Stream<Track?> watchTrackForUser(String uid) => _watch(() => _track);

  @override
  Stream<Map<String, DayEntry>> watchDays(
    String trackId, {
    required String fromKey,
  }) {
    return _watch(() {
      return <String, DayEntry>{
        for (final entry in _days.entries)
          if (entry.key.compareTo(fromKey) >= 0) entry.key: entry.value,
      };
    });
  }

  @override
  Future<String> createTrack({
    required String ownerUid,
    required String ownerName,
    required String? ownerPhotoUrl,
    required String? ownerPhone,
    required String promise,
    required String? promiseNote,
  }) async {
    final now = DateTime.now();
    final code = generateInviteCode();
    _track = Track(
      id: DemoIds.track,
      promise: promise,
      promiseNote: promiseNote,
      ownerUid: ownerUid,
      ownerName: ownerName,
      ownerPhotoUrl: ownerPhotoUrl,
      ownerPhone: ownerPhone,
      memberUids: <String>[ownerUid],
      inviteCode: code,
      inviteExpiresAt: now.add(const Duration(days: VouchConfig.inviteValidDays)),
      status: TrackStatus.waiting,
      createdAt: now,
      updatedAt: now,
    );
    _days.clear();
    _publish();
    return _track.id;
  }

  @override
  Future<InvitePreview?> previewInvite(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized != _track.inviteCode) return null;
    return InvitePreview(
      code: normalized,
      trackId: _track.id,
      ownerUid: _track.ownerUid,
      promise: _track.promise,
      ownerName: _track.ownerName,
      ownerPhotoUrl: _track.ownerPhotoUrl,
      expiresAt: _track.inviteExpiresAt,
    );
  }

  @override
  Future<void> joinTrack({
    required String code,
    required String uid,
    required String displayName,
    required String? photoUrl,
  }) async {
    final now = DateTime.now();
    _track = _track.copyWith(
      partnerUid: uid,
      partnerName: displayName,
      partnerPhotoUrl: photoUrl,
      memberUids: <String>[_track.ownerUid, uid],
      updatedAt: now,
    );
    _profiles[uid] ??= UserProfile(
      uid: uid,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: now,
    );
    _publish();
  }

  @override
  Future<void> updatePromise({
    required String trackId,
    required String promise,
    required String? promiseNote,
    required String? ownerPhone,
  }) async {
    _track = _track.copyWith(
      promise: promise,
      promiseNote: promiseNote,
      ownerPhone: ownerPhone,
      updatedAt: DateTime.now(),
    );
    _publish();
  }

  @override
  Future<void> updateOwnerPhone({
    required String trackId,
    required String? phone,
  }) async {
    _track = _track.copyWith(ownerPhone: phone, updatedAt: DateTime.now());
    _publish();
  }

  @override
  Future<void> updatePartnerPhone({
    required String trackId,
    required String? phone,
  }) async {
    _track = _track.copyWith(partnerPhone: phone, updatedAt: DateTime.now());
    _publish();
  }

  @override
  Future<void> updateSchedule({
    required String trackId,
    required VouchSchedule schedule,
    required DateTime? startedAt,
  }) async {
    _track = _track.copyWith(
      schedule: schedule,
      status: TrackStatus.active,
      startedAt: startedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _publish();
  }

  @override
  Future<void> refreshInvite(Track track) async {
    _track = _track.copyWith(
      inviteCode: generateInviteCode(),
      inviteExpiresAt:
          DateTime.now().add(const Duration(days: VouchConfig.inviteValidDays)),
      updatedAt: DateTime.now(),
    );
    _publish();
  }

  @override
  Future<void> saveNote({
    required String trackId,
    required String day,
    required String note,
  }) async {
    final existing = _days[day] ?? DayEntry(date: day);
    _days[day] = existing.copyWith(
      note: note,
      noteUpdatedAt: DateTime.now(),
    );
    _publish();
  }

  @override
  Future<void> markDay({
    required String trackId,
    required String day,
    required DayStatus status,
    required MarkMethod method,
    required String? partnerNote,
    required String uid,
  }) async {
    final existing = _days[day] ?? DayEntry(date: day);
    _days[day] = existing.copyWith(
      status: status,
      markedBy: uid,
      markedAt: DateTime.now(),
      method: method,
      partnerNote: partnerNote,
    );
    _publish();
  }

  @override
  Future<void> endTrack(String trackId) async {
    _track = _track.copyWith(
      status: TrackStatus.ended,
      endedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _publish();
  }

  @override
  Future<void> leaveTrack({
    required String trackId,
    required String uid,
  }) async {
    final now = DateTime.now();
    _track = Track(
      id: _track.id,
      promise: _track.promise,
      promiseNote: _track.promiseNote,
      ownerUid: _track.ownerUid,
      ownerName: _track.ownerName,
      ownerPhotoUrl: _track.ownerPhotoUrl,
      ownerPhone: _track.ownerPhone,
      memberUids: <String>[_track.ownerUid],
      inviteCode: _track.inviteCode,
      inviteExpiresAt: _track.inviteExpiresAt,
      status: TrackStatus.waiting,
      createdAt: _track.createdAt,
      updatedAt: now,
    );
    _days.clear();
    _asPartner = false;
    _publish();
  }

  @override
  bool get supportsRoleSwitch => true;

  @override
  bool get demoIsPartner => _asPartner;

  @override
  Future<void> switchRole(bool asPartner) async {
    _asPartner = asPartner;
    _publish();
  }
}
