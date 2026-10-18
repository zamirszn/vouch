/// Chooses the one screen the signed-in user should see.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../state/track_controller.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_mark.dart';
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const BrandMark(size: 88),
                const SizedBox(height: 26),
                Text(
                  'Vouch could not\nreach the promise.',
                  textAlign: TextAlign.center,
                  style: text.displaySmall?.copyWith(
                    fontSize: 34,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ),
                if (onSignOut != null) ...<Widget>[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onSignOut,
                    child: const Text('Sign out'),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'If this keeps happening, check that this phone is online and that the Firestore rules are deployed.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
