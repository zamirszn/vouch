import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'components/vouch_scaffold.dart';
import 'components/vouch_icon.dart';
import 'core/constants.dart';
import 'design/vouch_theme.dart';
import 'design/vouch_tokens.dart';
import 'design/vouch_type.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/contact_service.dart';
import 'services/demo_repository.dart';
import 'services/firestore_track_repository.dart';
import 'services/notification_service.dart';
import 'services/track_repository.dart';
import 'state/auth_controller.dart';
import 'state/theme_controller.dart';
import 'state/track_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the status and navigation bars on every Android version, and
  // keep those bars transparent so the animated background reaches the edges.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      systemNavigationBarColor: Color(0x00000000),
      systemNavigationBarDividerColor: Color(0x00000000),
      systemNavigationBarContrastEnforced: false,
    ),
  );

  final notifications = NotificationService();
  await notifications.initialize();

  final theme = ThemeController();
  await theme.load();

  try {
    final TrackRepository repository;
    final AuthService? authService;

    if (VouchConfig.demoMode) {
      // Fully offline seed data so both roles can be demonstrated without an
      // account. Never enabled in a release build unless explicitly defined.
      repository = DemoTrackRepository(timeZone: notifications.localTimeZone);
      authService = null;
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      repository = FirestoreTrackRepository();
      authService = AuthService();
    }

    final auth = AuthController(
      authService,
      repository,
      demoMode: VouchConfig.demoMode,
    );
    final tracks = TrackController(repository, notifications, auth);

    unawaited(auth.start());
    unawaited(tracks.start());

    runApp(
      VouchApp(
        auth: auth,
        tracks: tracks,
        theme: theme,
        notifications: notifications,
        contact: const ContactService(),
      ),
    );
  } catch (error) {
    runApp(_BootFailureApp(message: error.toString()));
  }
}

/// Last-resort UI when Firebase itself cannot start. Material-free.
class _BootFailureApp extends StatelessWidget {
  const _BootFailureApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      color: VouchColors.canvas,
      builder: (context, child) => VouchScope(
        theme: VouchThemeData.dark,
        tone: VouchTone.missed,
        child: child ?? const SizedBox.shrink(),
      ),
      home: VouchScaffold(
        tone: VouchTone.missed,
        animateBackground: false,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 76,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VouchColors.coral.withValues(alpha: 0.14),
                      border: Border.all(
                        color: VouchColors.coral.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const VouchIcon(
                      VouchGlyph.closeCircle,
                      size: 32,
                      color: VouchColors.coral,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Vouch could not start.',
                    textAlign: TextAlign.center,
                    style: VouchType.title(VouchColors.ink),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: VouchType.body(VouchColors.muted),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Check the Firebase configuration and that this build '
                    'includes google-services.json.',
                    textAlign: TextAlign.center,
                    style: VouchType.caption(VouchColors.faint),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
