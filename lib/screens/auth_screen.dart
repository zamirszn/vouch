/// Google-only sign-in, staged as a glass panel over the atmosphere.
library;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../components/glass_card.dart';
import '../components/pressable.dart';
import '../components/reveal.dart';
import '../components/vouch_icon.dart';
import '../components/vouch_loader.dart';
import '../components/vouch_scaffold.dart';
import '../components/vouch_top_bar.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../state/auth_controller.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = VouchScope.of(context);

    return VouchScaffold(
      tone: VouchTone.pending,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            VouchSpace.gutter,
            VouchSpace.x3,
            VouchSpace.gutter,
            MediaQuery.viewPaddingOf(context).bottom + VouchSpace.x6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Reveal(
                index: 0,
                child: VouchTopBar(annotation: '(001) / SIGN IN'),
              ),
              const SizedBox(height: VouchSpace.x10),
              Reveal(
                index: 1,
                child: Text(
                  'One promise.\nOne witness.',
                  style: VouchType.hero(theme.ink).copyWith(
                    fontSize: 52,
                    height: 0.94,
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x4),
              Container(
                width: 56,
                height: 2,
                decoration: BoxDecoration(
                  color: theme.accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: VouchSpace.x4),
              Reveal(
                index: 2,
                child: Text(
                  'One daily promise, witnessed by someone you trust.',
                  style: VouchType.body(theme.muted)
                      .copyWith(fontSize: 15, height: 1.45),
                ),
              ),
              const SizedBox(height: VouchSpace.x8),
              const Reveal(index: 3, child: _FeaturePanel()),
              const SizedBox(height: VouchSpace.x6),
              Reveal(
                index: 4,
                child: Column(
                  children: <Widget>[
                    if (auth.error != null) ...<Widget>[
                      GlassCard(
                        radius: VouchRadius.medium,
                        padding: const EdgeInsets.all(16),
                        tint: theme.missed,
                        borderColor: theme.missed.withValues(alpha: 0.35),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            VouchIcon(
                              VouchGlyph.closeCircle,
                              size: 18,
                              color: theme.missed,
                            ),
                            const SizedBox(width: VouchSpace.x3),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: VouchType.caption(theme.ink)
                                    .copyWith(fontSize: 13, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: VouchSpace.x3),
                    ],
                    _GoogleButton(auth: auth),
                  ],
                ),
              ),
              const SizedBox(height: VouchSpace.x6),
              Container(height: 1, color: theme.line),
              const SizedBox(height: VouchSpace.x4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Private.', style: VouchType.body(theme.muted)),
                        const SizedBox(height: 2),
                        Text(
                          'Between you and your witness.',
                          style: VouchType.caption(theme.faint),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '(EST. MMXXVI)',
                    style: VouchType.label(theme.faint, size: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel();

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return GlassCard(
      radius: VouchRadius.card,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Column(
        children: <Widget>[
          _FeatureRow(
            number: '01',
            color: theme.pending,
            title: 'One promise',
            body: 'A single thing you said you would do.',
          ),
          _FeatureRow(
            number: '02',
            color: theme.missed,
            title: 'One witness',
            body: 'Sets the reminder. Marks what happened.',
            rule: true,
          ),
          _FeatureRow(
            number: '03',
            color: theme.kept,
            title: 'The same nudge',
            body: 'Both phones buzz together.',
            rule: true,
          ),
        ],
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
    this.rule = false,
  });

  final String number;
  final Color color;
  final String title;
  final String body;

  /// Draws a rule above this row.
  final bool rule;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: rule ? Border(top: BorderSide(color: theme.line)) : null,
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
          const SizedBox(width: 10),
          Text(number, style: VouchType.mono(theme.faint, size: 9)),
          const SizedBox(width: VouchSpace.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: VouchType.bodyStrong(theme.ink)
                      .copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: VouchType.caption(theme.muted)
                      .copyWith(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final enabled = !auth.isSigningIn;
    final background = theme.isDark
        ? const Color(0xFFF6F6F2)
        : const Color(0xFF0B0B0C);
    final foreground = theme.isDark
        ? const Color(0xFF0B0B0C)
        : const Color(0xFFF6F6F2);

    return Semantics(
      button: true,
      label: 'Continue with Google',
      child: Pressable(
        onTap: enabled ? () => auth.signInWithGoogle() : null,
        scale: 0.975,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.65,
          duration: VouchDurations.fast,
          child: Container(
            height: 62,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(VouchRadius.pill),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'G',
                    style: VouchType.title(const Color(0xFF4285F4)).copyWith(
                      fontSize: 22,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(width: VouchSpace.x3),
                Expanded(
                  child: Text(
                    'Continue with Google',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VouchType.bodyStrong(foreground)
                        .copyWith(fontSize: 15.5),
                  ),
                ),
                const SizedBox(width: VouchSpace.x2),
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.accent,
                    shape: BoxShape.circle,
                  ),
                  child: auth.isSigningIn
                      ? VouchLoader(
                          size: 18,
                          color: const Color(0xFF0B0B0C),
                        )
                      : const VouchIcon(
                          VouchGlyph.arrowRight,
                          size: 19,
                          color: Color(0xFF0B0B0C),
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
