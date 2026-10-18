/// Choose: owner creating a promise, or partner joining one.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../theme/vouch_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_mark.dart';
import '../widgets/pressable_spring.dart';
import '../widgets/reveal.dart';
import '../widgets/vouch_avatar.dart';
import 'create_track_screen.dart';
import 'join_track_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const BrandMark(size: 46, animate: false, showShadow: false),
                    const SizedBox(width: 10),
                    Text(
                      'Vouch',
                      style: text.titleLarge?.copyWith(letterSpacing: -0.3),
                    ),
                    const Spacer(),
                    VouchAvatar(
                      name: auth.displayName,
                      photoUrl: auth.photoUrl,
                      size: 42,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Reveal(
                  child: Text(
                    'What brings you\nto Vouch?',
                    style: text.displaySmall?.copyWith(
                      fontSize: 42,
                      height: 1.03,
                      letterSpacing: -1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    'Pick your side.',
                    style: text.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Reveal(
                  delay: const Duration(milliseconds: 150),
                  child: _RoleCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CreateTrackScreen(),
                      ),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[Color(0xFF6B5BFF), Color(0xFF33229B)],
                    ),
                    foreground: Colors.white,
                    eyebrow: 'I am the owner',
                    title: 'I’m making\na promise',
                    body:
                        'One daily promise. Invite a witness.',
                    icon: Icons.flag_rounded,
                  ),
                ),
                const SizedBox(height: 16),
                Reveal(
                  delay: const Duration(milliseconds: 220),
                  child: _RoleCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const JoinTrackScreen(),
                      ),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        VouchColors.coral.withValues(alpha: 0.22),
                        VouchColors.coral.withValues(alpha: 0.10),
                      ],
                    ),
                    foreground: scheme.onSurface,
                    eyebrow: 'I am the partner',
                    title: 'I’m here\nfor someone',
                    body:
                        'Set the rhythm. Mark the days.',
                    icon: Icons.visibility_rounded,
                    outlined: true,
                  ),
                ),
                const SizedBox(height: 26),
                Center(
                  child: Text(
                    'One promise at a time.',
                    style: text.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0.6,
                    ),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.onTap,
    required this.gradient,
    required this.foreground,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    this.outlined = false,
  });

  final VoidCallback onTap;
  final Gradient gradient;
  final Color foreground;
  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return PressableSpring(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 22, 24),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(32),
          border: outlined
              ? Border.all(color: VouchColors.coral.withValues(alpha: 0.4))
              : null,
          boxShadow: outlined
              ? null
              : <BoxShadow>[
                  BoxShadow(
                    color: VouchColors.indigo.withValues(alpha: 0.28),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    eyebrow.toUpperCase(),
                    style: text.labelSmall?.copyWith(
                      color: foreground.withValues(alpha: 0.72),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: text.headlineMedium?.copyWith(
                      color: foreground,
                      height: 1.05,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    style: text.bodyMedium?.copyWith(
                      color: foreground.withValues(alpha: 0.82),
                      height: 1.42,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: outlined
                    ? VouchColors.coral.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                icon,
                color: outlined ? VouchColors.coral : Colors.white,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
