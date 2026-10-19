/// Choose: promise owner or witness. Two cards, one deal.
library;

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../components/glass_card.dart';
import '../components/reveal.dart';
import '../components/vouch_icon.dart';
import '../components/vouch_scaffold.dart';
import '../components/vouch_top_bar.dart';
import '../design/vouch_route.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../state/auth_controller.dart';
import 'create_track_screen.dart';
import 'join_track_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

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
              Reveal(
                index: 0,
                child: VouchTopBar(
                  annotation: '(001)',
                  trailing: VouchAvatar(
                    initials: _initials(auth.displayName),
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x10),
              Reveal(
                index: 1,
                child: Text(
                  'A SMALL DEAL',
                  style: VouchType.label(theme.muted, size: 8.5),
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 2,
                child: Text.rich(
                  TextSpan(
                    style: VouchType.hero(theme.ink).copyWith(
                      fontSize: 50,
                      height: 0.94,
                      letterSpacing: -2,
                    ),
                    children: <InlineSpan>[
                      const TextSpan(text: 'Make a promise.\n'),
                      TextSpan(
                        text: 'Name a witness.',
                        style: TextStyle(color: theme.accent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x4),
              Container(
                width: 56,
                height: 2,
                decoration: BoxDecoration(
                  color: theme.lineStrong,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: VouchSpace.x4),
              Reveal(
                index: 3,
                child: Text(
                  'One promise. One person keeping you to it.',
                  style: VouchType.body(theme.muted)
                      .copyWith(fontSize: 15.5, height: 1.4),
                ),
              ),
              const SizedBox(height: VouchSpace.x8),
              Reveal(
                index: 4,
                child: _RoleCard(
                  number: '01',
                  glyph: VouchGlyph.star,
                  tone: theme.pending,
                  title: 'I’m promising',
                  body: 'Create the promise and name your witness.',
                  onTap: () => pushVouch(
                    context,
                    (context) => const CreateTrackScreen(),
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x3),
              Reveal(
                index: 5,
                child: _RoleCard(
                  number: '02',
                  glyph: VouchGlyph.eye,
                  tone: theme.kept,
                  title: 'I’m witnessing',
                  body: 'Join with a code and set the rhythm.',
                  onTap: () => pushVouch(
                    context,
                    (context) => const JoinTrackScreen(),
                  ),
                ),
              ),
              const SizedBox(height: VouchSpace.x8),
              Reveal(
                index: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(height: 1, color: theme.line),
                    const SizedBox(height: VouchSpace.x4),
                    Text('Vouch', style: VouchType.body(theme.muted)),
                    const SizedBox(height: 4),
                    Text(
                      'One promise. One witness.',
                      style: VouchType.caption(theme.faint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.number,
    required this.glyph,
    required this.tone,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String number;
  final VouchGlyph glyph;
  final Color tone;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return GlassCard(
      radius: VouchRadius.card,
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
      tint: tone,
      glow: true,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                '($number)',
                style: VouchType.label(theme.faint, size: 9),
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone,
                ),
                child: VouchIcon(
                  VouchGlyph.arrowUpRight,
                  size: 18,
                  color: VouchColors.paperInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: VouchSpace.x6),
          Row(
            children: <Widget>[
              VouchIcon(glyph, size: 18, color: tone),
              const SizedBox(width: VouchSpace.x2),
              Text(
                title,
                style: VouchType.title(theme.ink)
                    .copyWith(fontSize: 29, letterSpacing: -1.2),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: VouchType.caption(theme.muted)
                .copyWith(fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
