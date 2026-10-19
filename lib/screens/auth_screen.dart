/// Google-only sign-in, printed as a flame poster.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../widgets/poster.dart';
import '../widgets/pressable_spring.dart';
import '../widgets/reveal.dart';
import '../widgets/vouch_loader.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: PosterField(
        tone: PosterTone.flame,
        child: Builder(
          builder: (context) {
            final style = PosterStyle.of(context);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const PosterTopBar(right: '(001) / sign in'),
                    const SizedBox(height: 36),
                    const Reveal(
                      child: PosterHeadline(
                        'One promise.\nOne witness.',
                        size: 52,
                        accentTail: 2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 56,
                      height: 2,
                      color: PosterColors.cream.withValues(alpha: 0.55),
                    ),
                    const SizedBox(height: 16),
                    Reveal(
                      delay: const Duration(milliseconds: 100),
                      child: Text(
                        'One daily promise, witnessed by someone you trust.',
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 15,
                          height: 1.45,
                          color: style.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Reveal(
                      delay: Duration(milliseconds: 180),
                      child: PosterCard(
                        padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
                        child: Column(
                          children: <Widget>[
                            _FeatureRow(
                              number: '01',
                              color: PosterColors.cobalt,
                              title: 'One promise',
                              body: 'A single thing you said you would do.',
                            ),
                            _FeatureRow(
                              number: '02',
                              color: PosterColors.coral,
                              title: 'One witness',
                              body: 'Sets the reminder. Marks what happened.',
                            ),
                            _FeatureRow(
                              number: '03',
                              color: PosterColors.kelly,
                              title: 'The same nudge',
                              body: 'Both phones buzz together.',
                              last: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Reveal(
                      delay: const Duration(milliseconds: 260),
                      child: Column(
                        children: <Widget>[
                          if (auth.error != null)
                            PosterCard(
                              color: PosterColors.cream,
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                auth.error!,
                                style: const TextStyle(
                                  fontFamily: 'InstrumentSans',
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Color(0xFF7E1B14),
                                ),
                              ),
                            ),
                          if (auth.error != null) const SizedBox(height: 12),
                          _GoogleButton(auth: auth),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    const PosterFooter(
                      lead: 'Private.',
                      muted: 'Between you and your witness.',
                      trailing: PosterLabel('(EST. MMXXVI)'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    final enabled = !auth.isSigningIn;

    return Semantics(
      button: true,
      label: 'Continue with Google',
      child: PressableSpring(
        onTap: enabled ? () => auth.signInWithGoogle() : null,
        pressedScale: 0.975,
        enabled: enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.7,
          child: Container(
            height: 60,
            padding: const EdgeInsets.only(left: 8, right: 8),
            decoration: BoxDecoration(
              color: style.pill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Continue with Google',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: style.pillInk,
                      fontVariations: const <FontVariation>[
                        FontVariation('wght', 600),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: style.accent,
                    shape: BoxShape.circle,
                  ),
                  child: auth.isSigningIn
                      ? Center(
                          child: VouchLoader(size: 18, color: style.onAccent),
                        )
                      : Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: style.onAccent,
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.number,
    required this.color,
    required this.title,
    required this.body,
    this.last = false,
  });

  final String number;
  final Color color;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: style.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Text(
            number,
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 8.5,
              letterSpacing: 0.8,
              color: style.cardMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                    color: style.cardInk,
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 600),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 11.5,
                    height: 1.4,
                    color: style.cardMuted,
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
