/// Chooses the one screen the signed-in user should see.
library;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../components/vouch_button.dart';
import '../components/vouch_icon.dart';
import '../components/vouch_scaffold.dart';
import '../components/vouch_top_bar.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../state/auth_controller.dart';
import '../state/track_controller.dart';
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
      duration: VouchDurations.base,
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
    final theme = VouchScope.of(context);
    return VouchScaffold(
      tone: VouchTone.missed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VouchSpace.gutter,
            VouchSpace.x3,
            VouchSpace.gutter,
            VouchSpace.x6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const VouchTopBar(annotation: '(000) / BOOT'),
              const Spacer(),
              Text(
                'Vouch could not\nreach the promise.',
                style: VouchType.display(theme.ink).copyWith(
                  fontSize: 38,
                  height: 0.98,
                ),
              ),
              const SizedBox(height: VouchSpace.x4),
              Text(
                message,
                style: VouchType.caption(theme.muted)
                    .copyWith(fontSize: 13.5, height: 1.45),
              ),
              const SizedBox(height: VouchSpace.x6),
              VouchButton(
                label: 'Try again',
                glyph: VouchGlyph.refresh,
                expand: true,
                onPressed: () => onRetry(),
              ),
              if (onSignOut != null) ...<Widget>[
                const SizedBox(height: VouchSpace.x2),
                VouchButton(
                  label: 'Sign out',
                  style: VouchButtonStyle.ghost,
                  expand: true,
                  onPressed: () => onSignOut!(),
                ),
              ],
              const SizedBox(height: VouchSpace.x3),
              Text(
                'If this keeps happening, check that this phone is online '
                'and that the Firestore rules are deployed.',
                style: VouchType.caption(theme.faint)
                    .copyWith(fontSize: 11, height: 1.45),
              ),
              const Spacer(),
              Container(height: 1, color: theme.line),
              const SizedBox(height: VouchSpace.x4),
              Text('Vouch', style: VouchType.body(theme.muted)),
              const SizedBox(height: 4),
              Text(
                'The promise is still there.',
                style: VouchType.caption(theme.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
