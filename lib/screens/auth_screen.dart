/// Google-only sign-in, set as a printed poster.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../theme/vouch_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/brand_mark.dart';
import '../widgets/reveal.dart';
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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Reveal(child: BrandMark(size: 56)),
                      const Spacer(),
                      Text(
                        '(001) / SIGN IN',
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Reveal(
                    delay: const Duration(milliseconds: 60),
                    child: Text(
                      'One promise.',
                      style: text.displayLarge?.copyWith(
                        fontSize: 46,
                        height: 0.92,
                        letterSpacing: -2.6,
                      ),
                    ),
                  ),
                  Reveal(
                    delay: const Duration(milliseconds: 90),
                    child: Text(
                      'One witness.',
                      style: text.displayLarge?.copyWith(
                        fontSize: 46,
                        height: 0.92,
                        letterSpacing: -2.6,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontVariations: const <FontVariation>[
                          FontVariation('wght', 500),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(width: 56, height: 3, color: VouchColors.coral),
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
                  const SizedBox(height: 34),
                  const Reveal(
                    delay: Duration(milliseconds: 200),
                    child: _FeatureRow(
                      number: '01',
                      color: VouchColors.indigo,
                      title: 'One promise',
                      body: 'A single thing you said you would do.',
                    ),
                  ),
                  const Reveal(
                    delay: Duration(milliseconds: 260),
                    child: _FeatureRow(
                      number: '02',
                      color: VouchColors.coral,
                      title: 'One witness',
                      body: 'Sets the reminder. Marks what happened.',
                    ),
                  ),
                  const Reveal(
                    delay: Duration(milliseconds: 320),
                    child: _FeatureRow(
                      number: '03',
                      color: VouchColors.kept,
                      title: 'The same nudge',
                      body: 'Both phones buzz together.',
                    ),
                  ),
                  const SizedBox(height: 26),
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
                              borderRadius: BorderRadius.circular(16),
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
                              foregroundColor: VouchColors.cream,
                              shape: const StadiumBorder(),
                              side: BorderSide(
                                color: VouchColors.cream.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                            child: auth.isSigningIn
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: VouchLoader(
                                      size: 22,
                                      color: VouchColors.cream,
                                    ),
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
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'PRIVATE BETWEEN YOU AND YOUR WITNESS',
                      style: text.labelSmall?.copyWith(
                        color:
                            scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        letterSpacing: 1.3,
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
    required this.number,
    required this.color,
    required this.title,
    required this.body,
  });

  final String number;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(width: 6, height: 6, color: color),
              const SizedBox(width: 10),
              Text(
                number,
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 16),
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
        ),
        Container(
          height: 1,
          color: scheme.onSurface.withValues(alpha: 0.12),
        ),
      ],
    );
  }
}
