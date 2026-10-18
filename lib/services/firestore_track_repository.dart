/// Firebase-backed implementation of [TrackRepository].
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../core/constants.dart';
import '../core/failures.dart';
import '../core/firebase_config.dart';
import '../models/day_entry.dart';
import '../models/schedule.dart';
import '../models/track.dart';
import '../models/user_profile.dart';
import 'track_repository.dart';

class FirestoreTrackRepository implements TrackRepository {
  FirestoreTrackRepository({FirebaseFirestore? firestore})
      : _db = firestore ??
            FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: FirebaseConfig.firestoreDatabaseId,
            );

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreCollections.users);

  CollectionReference<Map<String, dynamic>> get _tracks =>
      _db.collection(FirestoreCollections.tracks);

  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection(FirestoreCollections.invites);

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return UserProfile.fromMap(uid, data);
    });
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return UserProfile.fromMap(uid, data);
  }

  @override
  Future<void> ensureProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
  }) async {
    final ref = _users.doc(uid);
    final snapshot = await ref.get();
    final trimmedName = displayName?.trim();
    final fallbackName = (email == null || email.isEmpty)
        ? 'Friend'
        : email.split('@').first;

    if (!snapshot.exists) {
      await ref.set(<String, dynamic>{
        'displayName': (trimmedName == null || trimmedName.isEmpty)
            ? fallbackName
            : trimmedName,
        'email': email ?? '',
        'photoUrl': photoUrl,
        'phone': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = snapshot.data() ?? const <String, dynamic>{};
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (email != null && email.isNotEmpty && data['email'] != email) {
      updates['email'] = email;
    }
    if (photoUrl != null &&
        photoUrl.isNotEmpty &&
        data['photoUrl'] != photoUrl) {
      updates['photoUrl'] = photoUrl;
    }
    final existingName = (data['displayName'] as String?)?.trim() ?? '';
    if (existingName.isEmpty &&
        trimmedName != null &&
        trimmedName.isNotEmpty) {
      updates['displayName'] = trimmedName;
    }

    await ref.update(updates);
  }

  @override
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? phone,
  }) async {
    final updates = <String, dynamic>{
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final trimmedName = displayName?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      updates['displayName'] = trimmedName;
    }
    await _users.doc(uid).update(updates);
  }

  @override
  Stream<Track?> watchTrackForUser(String uid) {
    return _tracks
        .where('memberUids', arrayContains: uid)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      final tracks = snapshot.docs
          .map((doc) => Track.fromMap(doc.id, doc.data()))
          .where((track) => !track.isEnded)
          .toList()
        ..sort((a, b) {
          final left = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        });
      return tracks.isEmpty ? null : tracks.first;
    });
  }

  @override
  Stream<Map<String, DayEntry>> watchDays(
    String trackId, {
    required String fromKey,
  }) {
    return _tracks
        .doc(trackId)
        .collection(FirestoreCollections.days)
        .where('date', isGreaterThanOrEqualTo: fromKey)
        .orderBy('date')
        .limit(200)
        .snapshots()
        .map((snapshot) => <String, DayEntry>{
              for (final doc in snapshot.docs)
                doc.id: DayEntry.fromMap(doc.id, doc.data()),
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
    final trackRef = _tracks.doc();

    for (var attempt = 0; attempt < 6; attempt++) {
      final code = generateInviteCode();
      final inviteRef = _invites.doc(code);
      final expiresAt = DateTime.now().add(
        const Duration(days: VouchConfig.inviteValidDays),
      );

      try {
        await _db.runTransaction((transaction) async {
          final existing = await transaction.get(inviteRef);
          if (existing.exists) {
            throw const _InviteCollision();
          }

          transaction.set(trackRef, <String, dynamic>{
            'promise': promise,
            'promiseNote': promiseNote,
            'ownerUid': ownerUid,
            'ownerName': ownerName,
            'ownerPhotoUrl': ownerPhotoUrl,
            'ownerPhone': ownerPhone,
            'partnerUid': null,
            'partnerName': null,
            'partnerPhotoUrl': null,
            'partnerPhone': null,
            'memberUids': <String>[ownerUid],
            'inviteCode': code,
            'inviteExpiresAt': Timestamp.fromDate(expiresAt),
            'schedule': null,
            'status': TrackStatus.waiting.name,
            'startedAt': null,
            'endedAt': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          transaction.set(inviteRef, <String, dynamic>{
            'trackId': trackRef.id,
            'ownerUid': ownerUid,
            'promise': promise,
            'ownerName': ownerName,
            'ownerPhotoUrl': ownerPhotoUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(expiresAt),
          });
        });
        return trackRef.id;
      } on _InviteCollision {
        continue;
      }
    }

    throw const VouchFailure(
      'Could not reserve an invite code. Please try again.',
    );
  }

  @override
  Future<InvitePreview?> previewInvite(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.length != VouchConfig.inviteLength) return null;
    final snapshot = await _invites.doc(normalized).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return InvitePreview.fromMap(normalized, data);
  }

  @override
  Future<void> joinTrack({
    required String code,
    required String uid,
    required String displayName,
    required String? photoUrl,
  }) async {
    final normalized = code.trim().toUpperCase();
    final inviteRef = _invites.doc(normalized);

    await _db.runTransaction((transaction) async {
      final inviteSnapshot = await transaction.get(inviteRef);
      final data = inviteSnapshot.data();
      if (!inviteSnapshot.exists || data == null) {
        throw const VouchFailure('That invite code is not valid.');
      }

      final expiresAt = data['expiresAt'];
      if (expiresAt is Timestamp &&
          !expiresAt.toDate().isAfter(DateTime.now())) {
        throw const VouchFailure(
          'That invite has expired. Ask for a fresh code.',
        );
      }

      final trackId = data['trackId'] as String?;
      if (trackId == null || trackId.isEmpty) {
        throw const VouchFailure('That invite is incomplete. Ask for a new one.');
      }

      transaction.update(_tracks.doc(trackId), <String, dynamic>{
        'partnerUid': uid,
        'partnerName': displayName,
        'partnerPhotoUrl': photoUrl,
        'memberUids': FieldValue.arrayUnion(<String>[uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> updatePromise({
    required String trackId,
    required String promise,
    required String? promiseNote,
    required String? ownerPhone,
  }) async {
    await _tracks.doc(trackId).update(<String, dynamic>{
      'promise': promise,
      'promiseNote': promiseNote,
      'ownerPhone': ownerPhone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateOwnerPhone({
    required String trackId,
    required String? phone,
  }) async {
    await _tracks.doc(trackId).update(<String, dynamic>{
      'ownerPhone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updatePartnerPhone({
    required String trackId,
    required String? phone,
  }) async {
    await _tracks.doc(trackId).update(<String, dynamic>{
      'partnerPhone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateSchedule({
    required String trackId,
    required VouchSchedule schedule,
    required DateTime? startedAt,
  }) async {
    await _tracks.doc(trackId).update(<String, dynamic>{
      'schedule': schedule.toMap(),
      'status': TrackStatus.active.name,
      if (startedAt == null) 'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> refreshInvite(Track track) async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final code = generateInviteCode();
      final expiresAt = DateTime.now().add(
        const Duration(days: VouchConfig.inviteValidDays),
      );

      try {
        await _db.runTransaction((transaction) async {
          final existing = await transaction.get(_invites.doc(code));
          if (existing.exists) {
            throw const _InviteCollision();
          }

          if (track.inviteCode.isNotEmpty && track.inviteCode != code) {
            transaction.delete(_invites.doc(track.inviteCode));
          }

          transaction.set(_invites.doc(code), <String, dynamic>{
            'trackId': track.id,
            'ownerUid': track.ownerUid,
            'promise': track.promise,
            'ownerName': track.ownerName,
            'ownerPhotoUrl': track.ownerPhotoUrl,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(expiresAt),
          });
          transaction.update(_tracks.doc(track.id), <String, dynamic>{
            'inviteCode': code,
            'inviteExpiresAt': Timestamp.fromDate(expiresAt),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
        return;
      } on _InviteCollision {
        continue;
      }
    }
    throw const VouchFailure('Could not create a fresh invite code.');
  }

  @override
  Future<void> saveNote({
    required String trackId,
    required String day,
    required String note,
  }) async {
    await _tracks
        .doc(trackId)
        .collection(FirestoreCollections.days)
        .doc(day)
        .set(<String, dynamic>{
      'date': day,
      'note': note,
      'noteUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
    await _tracks
        .doc(trackId)
        .collection(FirestoreCollections.days)
        .doc(day)
        .set(<String, dynamic>{
      'date': day,
      'status': status.name,
      'markedBy': uid,
      'markedAt': FieldValue.serverTimestamp(),
      'method': method.name,
      'partnerNote': partnerNote,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> endTrack(String trackId) async {
    await _tracks.doc(trackId).update(<String, dynamic>{
      'status': TrackStatus.ended.name,
      'endedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> leaveTrack({required String trackId, required String uid}) async {
    // The partner clears their slot; memberUids must end up holding just the
    // owner. The owner cannot leave their own track (the UI ends it instead).
    await _tracks.doc(trackId).update(<String, dynamic>{
      'partnerUid': null,
      'partnerName': null,
      'partnerPhotoUrl': null,
      'partnerPhone': null,
      'schedule': null,
      'startedAt': null,
      'status': TrackStatus.waiting.name,
      'memberUids': FieldValue.arrayRemove(<String>[uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  bool get supportsRoleSwitch => false;

  @override
  bool get demoIsPartner => false;

  @override
  Future<void> switchRole(bool asPartner) async {}
}

class _InviteCollision implements Exception {
  const _InviteCollision();
}
