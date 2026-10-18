/// Firebase-specific constants that are not part of `firebase_options.dart`.
library;

class FirebaseConfig {
  const FirebaseConfig._();

  /// The **web** OAuth client ID of the `vouch-tracker` Firebase project.
  ///
  /// `google_sign_in` needs this as the `serverClientId` on Android so it can
  /// return an ID token that Firebase Auth can exchange for a session. The
  /// Firebase-console "enable Google" flow creates this client automatically.
  /// It is not a secret; it can be committed.
  static const String serverClientId = String.fromEnvironment(
    'VOUCH_WEB_CLIENT_ID',
    defaultValue: '171947197606-o2u4j0j9ggn9v4fjgbkgbpm6vddc5hns.apps.googleusercontent.com',
  );

  /// Whether Google sign-in is fully configured.
  static bool get isSignInConfigured => serverClientId.isNotEmpty;

  /// The Firestore database this project uses.
  ///
  /// The `vouch-tracker` project's database was provisioned with the literal
  /// ID `default`, not the conventional `(default)` alias. Client SDKs resolve
  /// `(default)` to a database that does not exist in this project, so every
  /// query fails with NOT_FOUND unless the ID is passed explicitly.
  static const String firestoreDatabaseId = 'default';
}
