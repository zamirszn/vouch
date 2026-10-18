/// Google-only sign-in.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../theme/vouch_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_mark.dart';
import '../widgets/reveal.dart';
import '../widgets/soul.dart';
import '../widgets/vouch_loader.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Reveal(child: BrandMark(size: 76)),
                  const SizedBox(height: 26),
                  Reveal(
                    delay: const Duration(milliseconds: 60),
                    child: Row(
                      children: <Widget>[
                        Asterisk(size: 11, color: scheme.secondary),
                        const SizedBox(width: 7),
                        Text(
                          'ACCOUNTABILITY, SIMPLIFIED',
                          style: text.labelSmall?.copyWith(
                            color: scheme.primary,
                            letterSpacing: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Reveal(
                    delay: const Duration(milliseconds: 80),
                    child: Text(
                      'One promise.\nOne witness.',
                      style: text.displaySmall?.copyWith(
                        fontSize: 44,
                        height: 1.02,
                        letterSpacing: -1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Reveal(
                    delay: Duration(milliseconds: 110),
                    child: Squiggle(
                      width: 148,
                      height: 9,
                      strokeWidth: 2.8,
                      color: VouchColors.coral,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Reveal(
                    delay: const Duration(milliseconds: 140),
                    child: Text(
                      'One daily promise, witnessed by someone you trust.',
                      style: text.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Reveal(
                    delay: Duration(milliseconds: 200),
                    child: _FeatureRow(
                      icon: Icons.flag_rounded,
                      color: VouchColors.indigo,
                      title: 'One promise',
                      body: 'A single thing you said you would do.',
                    ),
                  ),
                  const Reveal(
                    delay: Duration(milliseconds: 260),
                    child: _FeatureRow(
                      icon: Icons.visibility_rounded,
                      color: VouchColors.coral,
                      title: 'One witness',
                      body: 'Sets the reminder. Marks what happened.',
                    ),
                  ),
                  const Reveal(
                    delay: Duration(milliseconds: 320),
                    child: _FeatureRow(
                      icon: Icons.notifications_active_rounded,
                      color: Color(0xFF5F9E1F),
                      title: 'The same nudge',
                      body: 'Both phones buzz together.',
                    ),
                  ),
                  const SizedBox(height: 28),
                  Reveal(
                    delay: const Duration(milliseconds: 380),
                    child: Column(
                      children: <Widget>[
                        if (auth.error != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              auth.error!,
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onErrorContainer,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          height: 62,
                          child: FilledButton(
                            onPressed: auth.isSigningIn
                                ? null
                                : () => auth.signInWithGoogle(),
                            style: FilledButton.styleFrom(
                              backgroundColor: VouchColors.ink,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                            child: auth.isSigningIn
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: VouchLoader(size: 22, color: Colors.white),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: <Widget>[
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'G',
                                          style: text.titleMedium?.copyWith(
                                            color: const Color(0xFF4285F4),
                                            fontSize: 19,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text('Continue with Google'),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Private between you and your witness.',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
