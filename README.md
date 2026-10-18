# Vouch

**One promise. One witness.**

Vouch is an Android-first Flutter app for a single daily commitment. One person
(the *owner*) makes a promise. A partner (the *witness*) sets the rhythm, is
reminded at the same moment as the owner, and marks each day kept or missed.
The owner writes what they did; the witness can call, message, or check in
person before marking.

Material 3 Expressive throughout: spring motion with
[`motor`](https://pub.dev/packages/motor), wavy progress, shape-morphing
loaders, connected button groups, fade-through tab switches and expressive page
transitions from [`expressive_m3`](https://pub.dev/packages/expressive_m3),
bold colour blocking, oversized type, floating surfaces, edge-to-edge layout,
and an animated background.

Type is set in **Bricolage Grotesque** (display, headlines, titles) paired with
**Manrope** (body and interface labels). Both variable fonts are bundled under
`assets/fonts/` with their OFL licences.

---

## Project facts

| | |
|---|---|
| App name | Vouch |
| Android package | `com.zamirszn.vouch` |
| Firebase project | `vouch-tracker` |
| Firestore database | `default`, `europe-west1` |
| Flutter / Dart | 3.47.x / 3.13.x |
| Min Android | 7.0 (API 24) |
| Sign-in | Google Sign-In only |

Firebase config is checked in at `lib/firebase_options.dart` and
`android/app/google-services.json` (these are not secrets). The Google web
OAuth client ID used by `google_sign_in` lives in `lib/core/firebase_config.dart`.

### Firestore database ID

This project's database is named literally **`default`**, not the conventional
`(default)` alias. Android's Firestore SDK resolves `(default)` automatically,
so without help every query fails with `NOT_FOUND: The database (default) does
not exist`. `FirebaseConfig.firestoreDatabaseId` is passed to
`FirebaseFirestore.instanceFor` in `FirestoreTrackRepository` to fix this. If
the database is ever recreated with the standard alias, drop that argument.

## Features

- **One promise per person.** The owner writes a promise and an optional why,
  then shares an 8-character invite code with their witness.
- **The witness sets the schedule:** every day, weekdays, or weekends, with a
  time and IANA timezone.
- **Both phones remind at the same moment.** Each device schedules its own
  local alarms in the promise's timezone — no Cloud Functions, no Blaze plan.
- **Daily note.** The owner records what they did (up to 2,000 characters).
- **Witness mark.** The witness marks the day kept or missed, records how they
  confirmed it (in person, call, message, other), and can leave a short note.
- **Contact shortcuts.** Call, WhatsApp, or SMS the other person from the app
  (needs a phone number saved in Settings).
- **History & stats.** Month calendar, current/best streak, days kept, kept
  rate, and a day-by-day detail sheet.
- **Material 3 Expressive motion** with reduced-motion support.
- **Light/dark/system themes**, persisted locally.

## Run it

```bash
flutter pub get
flutter run -d <device-id>
```

### Demo mode (no Firebase account needed)

```bash
flutter run --dart-define=VOUCH_DEMO=true
```

Demo mode uses an in-memory repository seeded with ~6 weeks of history for
"Zamir" and witness "Amara Okafor". In **You → Demo preview** you can switch
between the owner and witness sides without signing in. Demo mode is for debug
builds; the release app always talks to Firebase.

## Tests

```bash
flutter analyze
flutter test
```

Coverage includes day-key/date maths, schedule occurrence generation, streak
and completion calculations, Firestore model parsing, and a full demo-mode
widget flow (owner home → settings → witness side → mark sheet).

## Firebase setup

The project is already created and configured:

- Android app registered in `vouch-tracker` with debug and release SHA-1/SHA-256.
- Google sign-in provider enabled.
- `flutterfire configure` output committed (`firebase_options.dart`,
  `google-services.json`).

### Firestore rules

Rules live in `firestore.rules`; indexes in `firestore.indexes.json`.

On this project the Firebase CLI's database-management call asks for billing,
so `firebase deploy --only firestore` cannot manage rules on the Spark plan.
The rules were published from the Firebase Console (Firestore → Rules →
Publish). If you change `firestore.rules`, either publish the file in the
console or run:

```bash
firebase deploy --only firestore:rules --project vouch-tracker
```

on a project where the CLI can see the database.

The rules enforce:

- `users/{uid}` is readable and writable only by that user.
- A track is readable only by its `memberUids`.
- The owner creates the track and invite, edits the promise, and can end it.
- A witness can claim an unclaimed track only with a live invite that points
  back at that track, and only by changing partner fields.
- The witness owns the schedule, their phone number, and leaving the track.
- Day documents are split: the owner writes `note`/`noteUpdatedAt`; the witness
  writes `status`/`markedBy`/`markedAt`/`method`/`partnerNote`.
- Invite documents can be fetched by code (never listed), created only by the
  owner, and deleted only by the owner.

## Reminders (free-tier design)

`NotificationService` generates the next 60 active-day alarms in the promise's
timezone and schedules one notification per day with
`flutter_local_notifications`. This avoids weekly-repeat DST bugs and needs no
server.

Consequences to keep in mind:

- Both devices schedule independently, so both ring at the same wall-clock time
  in the track's timezone.
- When the witness changes the time, their device reschedules immediately. The
  owner's device reschedules the next time the app is opened or resumed (and on
  notification taps).
- Android 13+ needs notification permission; Android 12+ needs exact-alarm
  permission for on-the-minute delivery. The app asks from an in-app card in
  Settings and falls back to inexact alarms when exact alarms are denied.
- Some OEM battery managers (Xiaomi, Huawei, Samsung) may delay or suppress
  alarms. Allow Vouch to run in the background / disable battery optimisation
  for reliable reminders.

## Release builds & signing

The upload keystore is `android/app/upload-keystore.jks`. Credentials live in
`android/key.properties`, which is **gitignored** along with `*.jks` — back
both up somewhere safe; losing them means you cannot update the app on Play.

```bash
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release  # build/app/outputs/bundle/release/app-release.aab
```

Artifacts are copied to `dist/` for convenience:

```bash
mkdir -p dist
cp build/app/outputs/flutter-apk/app-release.apk dist/vouch-1.0.0.apk
cp build/app/outputs/bundle/release/app-release.aab dist/vouch-1.0.0.aab
```

Install on a USB/Wi-Fi-debugging device:

```bash
adb install -r dist/vouch-1.0.0.apk
```

### GitHub Actions

`.github/workflows/build.yml` is **manual only**. Open the repo's **Actions** tab,
choose **Build Vouch → Run workflow**, then pick:

- **target** — `apk`, `aab`, or `both`
- **demo** — build with the seeded demo repository (no Firebase account)

The run verifies the project (`flutter analyze`, `flutter test`) and uploads the
release artifacts. Without signing secrets Gradle falls back to debug signing;
add `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and `KEY_PASSWORD` as
repository secrets to produce upload-signed builds.

## Project layout

```
lib/
  core/        config, constants, date/schedule maths, error mapping
  models/      UserProfile, Track, VouchSchedule, DayEntry
  services/    auth, Firestore repository, demo repository,
               notifications, contact actions
  state/       AuthController, TrackController, ThemeController
  theme/       colour schemes, type scale, shapes, motion springs
  screens/     splash, auth, onboarding, create/join, waiting,
               schedule setup, role-aware home, history, settings
  widgets/     sheets, cards, status pills, calendar, confetti, backgrounds
tool/          brand asset generation and browser automation used during setup
```

## Brand

- Indigo `#5B4BFF`, coral `#FF6A55`, lime `#C9F27A`, cream `#FFF8F2`,
  ink `#171520`.
- The mark is deliberately simple: one bold cream check on an indigo
  gradient with a single coral dot as the witness.
- Adaptive launcher icon, monochrome themed icon, Android 12 splash, and a
  white notification silhouette (`res/drawable/ic_notification.png`).
- Brand source art lives in `assets/brand/`; regenerate icons with:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```
