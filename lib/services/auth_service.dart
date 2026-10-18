/// Google-only authentication on top of Firebase Auth.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/failures.dart';
import '../core/firebase_config.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  bool _googleReady = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> initialize() async {
    if (_googleReady) return;
    if (!FirebaseConfig.isSignInConfigured) {
      throw const VouchFailure(
        'Google sign-in is not configured. Reinstall the app or contact support.',
      );
    }
    await _google.initialize(serverClientId: FirebaseConfig.serverClientId);
    _googleReady = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await initialize();
    final account = await _google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const VouchFailure(
        'Google did not return a sign-in token. Please try again.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Firebase sign-out below is what actually ends the app session.
    }
    await _auth.signOut();
  }
}
