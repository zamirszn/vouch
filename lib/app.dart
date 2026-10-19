/// App wiring: providers, theme scope, lifecycle and notification taps.
///
/// The root is a [WidgetsApp], not a MaterialApp. There is no ThemeData,
/// ColorScheme or Material widget anywhere above the screen tree.
library;

import 'dart:async';

import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'design/vouch_route.dart';
import 'design/vouch_theme.dart';
import 'design/vouch_tokens.dart';
import 'design/vouch_type.dart';
import 'screens/gallery_screen.dart';
import 'screens/root_gate.dart';
import 'services/contact_service.dart';
import 'services/notification_service.dart';
import 'state/auth_controller.dart';
import 'state/theme_controller.dart';
import 'state/track_controller.dart';

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
            VouchThemeMode.dark => true,
            VouchThemeMode.light => false,
            VouchThemeMode.system => systemDark,
          };
          final themeData = isDark ? VouchThemeData.dark : VouchThemeData.light;
          final overlay = (isDark
                  ? SystemUiOverlayStyle.light
                  : SystemUiOverlayStyle.dark)
              .copyWith(
            statusBarColor: const Color(0x00000000),
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: const Color(0x00000000),
            systemNavigationBarDividerColor: const Color(0x00000000),
            systemNavigationBarContrastEnforced: false,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          );

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlay,
            child: WidgetsApp(
              title: VouchConfig.appName,
              color: themeData.canvas,
              debugShowCheckedModeBanner: false,
              textStyle: VouchType.body(themeData.ink),
              home: const bool.fromEnvironment('VOUCH_GALLERY')
                  ? const GalleryScreen()
                  : const RootGate(),
              pageRouteBuilder: vouchPageRoute,
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                DefaultCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => ScrollConfiguration(
                behavior: const VouchScrollBehavior(),
                child: VouchScope(
                  theme: themeData,
                  tone: VouchTone.pending,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Elastic, rubber-band scrolling everywhere — the touch feel Cuberto-style
/// sites aim for, rather than Android's hard edge.
class VouchScrollBehavior extends ScrollBehavior {
  const VouchScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
