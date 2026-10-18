/// Human-friendly error types and mapping for auth / Firestore failures.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class VouchFailure implements Exception {
  const VouchFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

String friendlyAuthError(Object error) {
  if (error is VouchFailure) return error.message;
  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) {
      return 'Sign-in was cancelled.';
    }
    return 'Google sign-in could not start. Please try again.';
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'network-request-failed' =>
        'No connection. Check your internet and try again.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' =>
        'That sign-in could not be verified. Please try again.',
      'user-disabled' => 'This Google account has been disabled.',
      'too-many-requests' => 'Too many attempts. Wait a minute, then retry.',
      'operation-not-allowed' =>
        'Google sign-in is not enabled for this project yet.',
      'account-exists-with-different-credential' =>
        'That email is already linked to a different sign-in method.',
      _ => 'Sign-in failed (${error.code}). Please try again.',
    };
  }
  return 'Something went wrong. Please try again.';
}

String friendlyDataError(Object error) {
  if (error is VouchFailure) return error.message;
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'You do not have permission to do that. Pull to refresh and retry.',
      'unavailable' =>
        'You appear to be offline. Changes will sync when you reconnect.',
      'not-found' => 'That invite could not be found.',
      'failed-precondition' => 'Firestore needs an index or setup step.',
      'deadline-exceeded' => 'The request timed out. Please try again.',
      _ => 'Something went wrong (${error.code}).',
    };
  }
  return 'Something went wrong. Please try again.';
}
