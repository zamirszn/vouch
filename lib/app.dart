/// App wiring: providers, theme, app lifecycle and notification taps.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'screens/root_gate.dart';
import 'services/contact_service.dart';
import 'services/notification_service.dart';
import 'state/auth_controller.dart';
import 'state/theme_controller.dart';
import 'state/track_controller.dart';
import 'theme/vouch_theme.dart';

class VouchApp extends StatefulWidget {
  const VouchApp({
    super.key,
    required this.auth,
    required this.tracks,
    required this.theme,
    required this.notifications,
    required this.contact,
  });

  final AuthController auth;
  final TrackController tracks;
  final ThemeController theme;
  final NotificationService notifications;
  final ContactService contact;

  @override
  State<VouchApp> createState() => _VouchAppState();
}

class _VouchAppState extends State<VouchApp> with WidgetsBindingObserver {
  StreamSubscription<String>? _taps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taps = widget.notifications.taps.listen((_) {
      // A tap opens the app at Today; rescheduling keeps the next 60 days fresh.
      unawaited(widget.tracks.refreshReminders());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(widget.notifications.initialize());
      unawaited(widget.tracks.refreshReminders());
    }
  }

  @override
  void dispose() {
    _taps?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: widget.auth),
        ChangeNotifierProvider<TrackController>.value(value: widget.tracks),
        ChangeNotifierProvider<ThemeController>.value(value: widget.theme),
        Provider<NotificationService>.value(value: widget.notifications),
        Provider<ContactService>.value(value: widget.contact),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
          final systemDark = WidgetsBinding
                  .instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
          final isDark = switch (theme.mode) {
            ThemeMode.dark => true,
            ThemeMode.light => false,
            ThemeMode.system => systemDark,
          };
          final overlay = (isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          );

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay,
            child: MaterialApp(
              title: VouchConfig.appName,
              debugShowCheckedModeBanner: false,
              theme: VouchTheme.light(),
              darkTheme: VouchTheme.dark(),
              themeMode: theme.mode,
              themeAnimationDuration: const Duration(milliseconds: 320),
              themeAnimationCurve: Curves.easeOutCubic,
              home: const RootGate(),
            ),
          );
        },
      ),
    );
  }
}
