/// Signed-in user + profile state.
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/failures.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/track_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(
    this._authService,
    this._repository, {
    required this.demoMode,
  });

  final AuthService? _authService;
  final TrackRepository _repository;
  final bool demoMode;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserProfile?>? _profileSub;

  User? _user;
  UserProfile? _profile;
  bool _initializing = true;
  bool _signingIn = false;
  String? _error;
  String? _profileUid;
  bool _started = false;

  bool get isInitializing => _initializing;
  bool get isSignedIn => demoMode || _user != null;
  bool get isSigningIn => _signingIn;
  String? get error => _error;
  UserProfile? get profile => _profile;

  String? get uid => demoMode ? DemoIds.owner : _user?.uid;

  String get displayName {
    final fromProfile = _profile?.displayName.trim();
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    final fromUser = _user?.displayName?.trim();
    if (fromUser != null && fromUser.isNotEmpty) return fromUser;
    return demoMode ? 'Zamir' : 'Friend';
  }

  String get email => _profile?.email ?? _user?.email ?? '';

  String? get photoUrl => _profile?.photoUrl ?? _user?.photoURL;

  String get initials {
    final name = displayName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;

    if (demoMode) {
      _profileSub = _repository.watchProfile(DemoIds.owner).listen((profile) {
        if (profile != null) {
          _profile = profile;
          notifyListeners();
        }
      });
      _initializing = false;
      notifyListeners();
      return;
    }

    final service = _authService;
    if (service == null) {
      _error = 'Sign-in is unavailable in this build.';
      _initializing = false;
      notifyListeners();
      return;
    }

    _authSub = service.authStateChanges.listen(
      (user) {
        _user = user;
        _initializing = false;
        _bindProfile(user);
        notifyListeners();
      },
      onError: (Object error) {
        _error = friendlyAuthError(error);
        _initializing = false;
        notifyListeners();
      },
    );
  }

  void _bindProfile(User? user) {
    if (user == null) {
      _profileUid = null;
      _profile = null;
      _profileSub?.cancel();
      _profileSub = null;
      return;
    }
    if (_profileUid == user.uid && _profileSub != null) return;
    _profileUid = user.uid;
    _profileSub?.cancel();
    _profileSub = null;
    unawaited(_loadProfile(user));
  }

  Future<void> _loadProfile(User user) async {
    try {
      await _repository.ensureProfile(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoUrl: user.photoURL,
      );
      if (_profileUid != user.uid) return;
      _profileSub = _repository.watchProfile(user.uid).listen((profile) {
        _profile = profile;
        notifyListeners();
      });
    } catch (error) {
      _error = friendlyDataError(error);
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    if (_signingIn) return false;
    _signingIn = true;
    _error = null;
    notifyListeners();
    final service = _authService;
    if (service == null) {
      _signingIn = false;
      _error = 'Sign-in is unavailable in this build.';
      notifyListeners();
      return false;
    }
    try {
      await service.signInWithGoogle();
      return true;
    } catch (error) {
      _error = friendlyAuthError(error);
      return false;
    } finally {
      _signingIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (demoMode) return;
    await _authService?.signOut();
    _profile = null;
    _profileUid = null;
    _profileSub?.cancel();
    _profileSub = null;
    notifyListeners();
  }

  Future<String?> saveProfile({String? displayName, String? phone}) async {
    final id = uid;
    if (id == null) return 'You are not signed in.';
    try {
      await _repository.updateProfile(
        uid: id,
        displayName: displayName,
        phone: phone,
      );
      return null;
    } catch (error) {
      return friendlyDataError(error);
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
