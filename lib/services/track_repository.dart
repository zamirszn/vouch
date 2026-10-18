/// Storage contract used by the app and by the offline demo repository.
library;

import 'dart:math';

import '../models/day_entry.dart';
import '../models/schedule.dart';
import '../models/track.dart';
import '../models/user_profile.dart';

abstract class TrackRepository {
  Stream<UserProfile?> watchProfile(String uid);

  Future<void> ensureProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
  });

  Future<UserProfile?> getProfile(String uid);

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? phone,
  });

  Stream<Track?> watchTrackForUser(String uid);

  Stream<Map<String, DayEntry>> watchDays(
    String trackId, {
    required String fromKey,
  });

  Future<String> createTrack({
    required String ownerUid,
    required String ownerName,
    required String? ownerPhotoUrl,
    required String? ownerPhone,
    required String promise,
    required String? promiseNote,
  });

  Future<InvitePreview?> previewInvite(String code);

  Future<void> joinTrack({
    required String code,
    required String uid,
    required String displayName,
    required String? photoUrl,
  });

  Future<void> updatePromise({
    required String trackId,
    required String promise,
    required String? promiseNote,
    required String? ownerPhone,
  });

  Future<void> updateOwnerPhone({
    required String trackId,
    required String? phone,
  });

  Future<void> updatePartnerPhone({
    required String trackId,
    required String? phone,
  });

  Future<void> updateSchedule({
    required String trackId,
    required VouchSchedule schedule,
    required DateTime? startedAt,
  });

  Future<void> refreshInvite(Track track);

  Future<void> saveNote({
    required String trackId,
    required String day,
    required String note,
  });

  Future<void> markDay({
    required String trackId,
    required String day,
    required DayStatus status,
    required MarkMethod method,
    required String? partnerNote,
    required String uid,
  });

  Future<void> endTrack(String trackId);

  Future<void> leaveTrack({required String trackId, required String uid});

  /// Demo-only: whether the current phone shows the owner or partner view.
  bool get supportsRoleSwitch => false;
  bool get demoIsPartner => false;
  Future<void> switchRole(bool asPartner) async {}
}

String generateInviteCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final random = Random.secure();
  return List<String>.generate(
    8,
    (_) => alphabet[random.nextInt(alphabet.length)],
    growable: false,
  ).join();
}
