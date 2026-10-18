/// App-wide constants and identifiers.
library;

class VouchConfig {
  const VouchConfig._();

  static const String appName = 'Vouch';
  static const String tagline = 'One promise. One witness.';

  /// Set with `--dart-define=VOUCH_DEMO=true` to run fully offline with seeded
  /// owner/partner data (used for QA and screenshots).
  static const bool demoMode = bool.fromEnvironment('VOUCH_DEMO');

  static const int maxPromiseLength = 140;
  static const int maxPromiseNoteLength = 240;
  static const int maxDailyNoteLength = 1000;
  static const int maxPartnerNoteLength = 240;
  static const int maxPhoneLength = 24;
  static const int inviteLength = 8;
  static const int inviteValidDays = 7;
  static const int scheduledReminderDays = 60;
  static const int historyWindowDays = 120;
}

/// Stable demo identities.
class DemoIds {
  const DemoIds._();
  static const String owner = 'demo-owner';
  static const String partner = 'demo-partner';
  static const String track = 'demo-track';
}

class FirestoreCollections {
  const FirestoreCollections._();
  static const String users = 'users';
  static const String tracks = 'tracks';
  static const String days = 'days';
  static const String invites = 'invites';
}
