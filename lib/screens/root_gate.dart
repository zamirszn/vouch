/// Chooses the one screen the signed-in user should see.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../state/track_controller.dart';
import '../widgets/poster.dart';
import '../widgets/pressable_spring.dart';
import 'auth_screen.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';
import 'schedule_setup_screen.dart';
import 'splash_screen.dart';
import 'waiting_screen.dart';

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final tracks = context.watch<TrackController>();

    final (String key, Widget child) state;

    if (auth.isInitializing) {
      state = ('splash', const SplashScreen());
    } else if (!auth.isSignedIn) {
      state = ('auth', const AuthScreen());
    } else if (tracks.loading) {
      state = ('loading', const SplashScreen());
    } else if (tracks.error != null && tracks.track == null) {
      state = (
        'error',
        _BootError(
          message: tracks.error!,
          onRetry: tracks.retry,
          onSignOut: auth.demoMode ? null : auth.signOut,
        ),
      );
    } else {
      final track = tracks.track;
      if (track == null || track.isEnded) {
        state = ('onboarding', const OnboardingScreen());
      } else if (!track.hasPartner) {
        state = ('waiting', const WaitingScreen());
      } else if (track.schedule == null) {
        state = ('schedule', const ScheduleSetupScreen());
      } else {
        state = ('home', const HomeShell());
      }
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 340),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: ValueKey<String>(state.$1), child: state.$2),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({
    required this.message,
    required this.onRetry,
    this.onSignOut,
  });

  final String message;
  final Future<void> Function() onRetry;
  final Future<void> Function()? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PosterField(
        tone: PosterTone.flame,
        child: Builder(
          builder: (context) {
            final style = PosterStyle.of(context);

            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const PosterTopBar(right: '(000) / boot'),
                  const Spacer(),
                  const PosterHeadline(
                    'Vouch could not\nreach the promise.',
                    size: 38,
                    accentTail: 2,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 13.5,
                      height: 1.45,
                      color: style.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PosterPill(
                    label: 'Try again',
                    icon: Icons.refresh_rounded,
                    color: PosterColors.cream,
                    foreground: PosterColors.ink,
                    arrowColor: PosterColors.coral,
                    arrowForeground: PosterColors.cream,
                    onPressed: onRetry,
                  ),
                  if (onSignOut != null) ...<Widget>[
                    const SizedBox(height: 8),
                    PressableSpring(
                      onTap: onSignOut,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: PosterLabel('Sign out', color: style.ink),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'If this keeps happening, check that this phone is online and that the Firestore rules are deployed.',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 11,
                      height: 1.45,
                      color: style.muted,
                    ),
                  ),
                  const Spacer(),
                  const PosterFooter(
                    lead: 'Vouch',
                    muted: 'The promise is still there.',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
