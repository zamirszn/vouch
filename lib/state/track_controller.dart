/// The user's single active track, its recent days, and all mutations.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../core/failures.dart';
import '../models/day_entry.dart';
import '../models/schedule.dart';
import '../models/track.dart';
import '../services/notification_service.dart';
import '../services/track_repository.dart';
import 'auth_controller.dart';

class TrackController extends ChangeNotifier {
  TrackController(
    this._repository,
    this._notifications,
    this._auth,
  );

  final TrackRepository _repository;
  final NotificationService _notifications;
  final AuthController _auth;

  StreamSubscription<Track?>? _trackSub;
  StreamSubscription<Map<String, DayEntry>>? _daysSub;
  bool _observingAuth = false;
  bool _disposed = false;

  String? _boundUid;
  String? _daysTrackId;
  String? _reminderSignature;

  Track? _track;
  Map<String, DayEntry> _days = const <String, DayEntry>{};
  bool _loading = true;
  bool _busy = false;
  String? _error;

  Track? get track => _track;
  Map<String, DayEntry> get days => _days;
  bool get loading => _loading;
  bool get busy => _busy;
  String? get error => _error;
  bool get hasTrack => _track != null;
  bool get hasPartner => _track?.hasPartner ?? false;
  bool get hasSchedule => _track?.schedule != null;
  bool get isLive => _track?.isLive ?? false;

  TrackRole get role {
    if (_repository.supportsRoleSwitch) {
      return _repository.demoIsPartner ? TrackRole.partner : TrackRole.owner;
    }
    return _track?.roleFor(_auth.uid) ?? TrackRole.none;
  }

  bool get isOwner => role == TrackRole.owner;
  bool get isPartner => role == TrackRole.partner;
  bool get isDemo => _repository.supportsRoleSwitch;

  String? get currentUid => _auth.uid;

  DateTime get today => todayIn(_track?.schedule?.timeZone);
  String get todayKey => dayKey(today);

  DayEntry? get todayEntry => _days[todayKey];

  VouchDayState dayState(DateTime date) => dayStateFor(
        schedule: _track?.schedule,
        entry: _days[dayKey(date)],
        date: date,
        today: today,
      );

  TrackStats get stats => computeStats(
        schedule: _track?.schedule,
        startedAt: _track?.startedAt,
        today: today,
        days: _days,
      );

  DateTime? get nextReminder => nextReminderAt(_track?.schedule);

  Duration? get timeToNextReminder {
    final next = nextReminder;
    if (next == null) return null;
    return next.difference(DateTime.now());
  }

  String? get ownerPhone => _track?.ownerPhone;

  String? get partnerPhone => _track?.partnerPhone;

  Future<void> start() async {
    if (!_observingAuth) {
      _auth.addListener(_handleAuthChanged);
      _observingAuth = true;
    }
    _handleAuthChanged();
  }

  /// Re-subscribes the track stream after a load error.
  Future<void> retry() async {
    final uid = _auth.uid;
    if (uid == null) return;
    _boundUid = null;
    _trackSub?.cancel();
    _trackSub = null;
    _handleAuthChanged();
  }

  void _handleAuthChanged() {    final uid = _auth.uid;
    if (uid == null) {
      if (_boundUid == null && !_loading) return;
      _teardown();
      _boundUid = null;
      _track = null;
      _days = const <String, DayEntry>{};
      _loading = false;
      _notify();
      return;
    }
    if (_boundUid == uid) return;
    _boundUid = uid;
    _bindTrack(uid);
  }

  void _bindTrack(String uid) {
    _trackSub?.cancel();
    _daysSub?.cancel();
    _daysSub = null;
    _daysTrackId = null;
    _track = null;
    _days = const <String, DayEntry>{};
    _loading = true;
    _error = null;
    _notify();

    _trackSub = _repository.watchTrackForUser(uid).listen(
      (track) {
        if (_disposed) return;
        final hadTrack = _track != null;
        _track = track;
        _loading = false;
        _error = null;
        if (track != null) {
          _bindDays(track);
          _scheduleReminders(track);
        } else {
          _days = const <String, DayEntry>{};
          _daysTrackId = null;
          _daysSub?.cancel();
          _daysSub = null;
          _reminderSignature = null;
          unawaited(_notifications.cancelAll());
        }
        // Re-schedule after the partner joins (waiting -> active).
        if (!hadTrack && track != null && track.isLive) {
          unawaited(refreshReminders());
        }
        _notify();
      },
      onError: (Object error) {
        if (_disposed) return;
        _error = friendlyDataError(error);
        _loading = false;
        _notify();
      },
    );
  }

  void _bindDays(Track track) {
    if (_daysTrackId == track.id) return;
    _daysTrackId = track.id;
    _daysSub?.cancel();

    final start = dateAt(todayIn(track.schedule?.timeZone), -VouchConfig.historyWindowDays);
    _daysSub = _repository
        .watchDays(track.id, fromKey: dayKey(start))
        .listen(
      (days) {
        if (_disposed) return;
        _days = days;
        _notify();
      },
      onError: (Object error) {
        if (_disposed) return;
        _error = friendlyDataError(error);
        _notify();
      },
    );
  }

  void _scheduleReminders(Track track) {
    final schedule = track.schedule;
    final signature = <String?>[
      track.id,
      track.status.name,
      track.promise,
      schedule?.kind.name,
      schedule?.hour.toString(),
      schedule?.minute.toString(),
      schedule?.timeZone,
      role.name,
    ].join('|');
    if (signature == _reminderSignature) return;
    _reminderSignature = signature;
    unawaited(
      _notifications.scheduleReminders(track: track, asPartner: isPartner),
    );
  }

  Future<void> refreshReminders() async {
    final track = _track;
    if (track == null) {
      await _notifications.cancelAll();
      return;
    }
    _reminderSignature = null;
    _scheduleReminders(track);
  }

  Future<String?> createTrack({
    required String promise,
    String? promiseNote,
    String? phone,
  }) async {
    final uid = _auth.uid;
    if (uid == null) return 'Sign in to start a promise.';
    return _run(() async {
      await _repository.createTrack(
        ownerUid: uid,
        ownerName: _auth.displayName,
        ownerPhotoUrl: _auth.photoUrl,
        ownerPhone: phone,
        promise: promise.trim(),
        promiseNote: promiseNote?.trim().isEmpty ?? true
            ? null
            : promiseNote!.trim(),
      );
    });
  }

  Future<InvitePreview?> previewInvite(String code) =>
      _repository.previewInvite(code);

  Future<String?> joinTrack(String code) async {
    final uid = _auth.uid;
    if (uid == null) return 'Sign in to join a promise.';
    return _run(() async {
      await _repository.joinTrack(
        code: code.trim().toUpperCase(),
        uid: uid,
        displayName: _auth.displayName,
        photoUrl: _auth.photoUrl,
      );
    });
  }

  Future<String?> saveSchedule(VouchSchedule schedule) async {
    final track = _track;
    if (track == null) return 'Create or join a promise first.';
    return _run(() async {
      await _repository.updateSchedule(
        trackId: track.id,
        schedule: schedule,
        startedAt: track.startedAt,
      );
      await refreshReminders();
    });
  }

  Future<String?> refreshInvite() async {
    final track = _track;
    if (track == null) return 'No promise to invite someone to.';
    return _run(() => _repository.refreshInvite(track));
  }

  Future<String?> saveNote(String note) async {
    final track = _track;
    if (track == null) return 'No promise yet.';
    final trimmed = note.trim();
    if (trimmed.length > VouchConfig.maxDailyNoteLength) {
      return 'That note is a little too long.';
    }
    return _run(() async {
      await _repository.saveNote(
        trackId: track.id,
        day: todayKey,
        note: trimmed,
      );
    });
  }

  Future<String?> markDay({
    required String day,
    required DayStatus status,
    required MarkMethod method,
    String? partnerNote,
  }) async {
    if (!isPartner) {
      return 'Only the accountability partner can mark a day.';
    }
    final track = _track;
    final uid = _auth.uid;
    if (track == null || uid == null) return 'No promise to mark.';
    final trimmed = partnerNote?.trim();
    if ((trimmed?.length ?? 0) > VouchConfig.maxPartnerNoteLength) {
      return 'That note is a little too long.';
    }
    return _run(() async {
      await _repository.markDay(
        trackId: track.id,
        day: day,
        status: status,
        method: method,
        partnerNote: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        uid: uid,
      );
    });
  }

  Future<String?> markToday({
    required DayStatus status,
    required MarkMethod method,
    String? partnerNote,
  }) {
    return markDay(
      day: todayKey,
      status: status,
      method: method,
      partnerNote: partnerNote,
    );
  }

  Future<String?> saveMyPhone(String? phone) async {
    final uid = _auth.uid;
    final track = _track;
    final trimmed = phone?.trim();
    final value =
        (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    return _run(() async {
      if (uid != null) {
        await _repository.updateProfile(uid: uid, phone: value);
      }
      if (track != null && isOwner) {
        await _repository.updateOwnerPhone(trackId: track.id, phone: value);
      } else if (track != null && isPartner) {
        await _repository.updatePartnerPhone(trackId: track.id, phone: value);
      }
    });
  }

  Future<String?> endTrack() async {
    final track = _track;
    if (track == null || !isOwner) return 'Only the owner can end this promise.';
    return _run(() => _repository.endTrack(track.id));
  }

  Future<String?> leaveTrack() async {
    final track = _track;
    final uid = _auth.uid;
    if (track == null || uid == null) return 'Nothing to leave.';
    if (!isPartner) return 'Only the partner can leave this promise.';
    return _run(() => _repository.leaveTrack(trackId: track.id, uid: uid));
  }

  Future<void> switchDemoRole(bool asPartner) async {
    if (!_repository.supportsRoleSwitch) return;
    await _repository.switchRole(asPartner);
    _reminderSignature = null;
    _notify();
    await refreshReminders();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    _notify();
  }

  Future<String?> _run(Future<void> Function() action) async {
    if (_busy) return 'Hold on — still saving.';
    _busy = true;
    _error = null;
    _notify();
    try {
      await action();
      return null;
    } catch (error) {
      final message = friendlyDataError(error);
      _error = message;
      return message;
    } finally {
      _busy = false;
      _notify();
    }
  }

  void _teardown() {
    _trackSub?.cancel();
    _trackSub = null;
    _daysSub?.cancel();
    _daysSub = null;
    _daysTrackId = null;
    _reminderSignature = null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_observingAuth) _auth.removeListener(_handleAuthChanged);
    _teardown();
    super.dispose();
  }
}
