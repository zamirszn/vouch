/// Choose: owner creating a promise, or partner joining one.
///
/// Page one is a butter poster; page two is the cream choice sheet. The
/// liquid swipe between them is the whole interaction.
library;

import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../widgets/poster.dart';
import '../widgets/pressable_spring.dart';
import '../widgets/vouch_avatar.dart';
import 'create_track_screen.dart';
import 'join_track_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final LiquidController _controller = LiquidController();
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: LiquidSwipe(
        liquidController: _controller,
        waveType: WaveType.liquidReveal,
        enableSideReveal: true,
        enableLoop: false,
        slideIconWidget: _SwipeCue(page: _page),
        preferDragFromRevealedArea: true,
        onPageChangeCallback: (page) {
          if (page != _page) setState(() => _page = page);
        },
        pages: <Widget>[
          _PromisePage(auth: auth),
          _RolePage(auth: auth),
        ],
      ),
    );
  }
}

class _SwipeCue extends StatelessWidget {
  const _SwipeCue({required this.page});

  final int page;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: PosterColors.ink,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: page == 0 ? PosterColors.acid : PosterColors.cream,
        size: 22,
      ),
    );
  }
}

class _PromisePage extends StatelessWidget {
  const _PromisePage({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return PosterField(
      tone: PosterTone.butter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PosterTopBar(
              right: '(001)',
              trailing: VouchAvatar(
                name: auth.displayName,
                photoUrl: auth.photoUrl,
                size: 36,
              ),
            ),
            const Spacer(),
            const PosterLabel('A small deal', size: 8.5),
            const SizedBox(height: 16),
            const PosterHeadline('Make a\npromise.', size: 54),
            const PosterHeadline('Name a witness.', size: 54, accentTail: 2),
            const SizedBox(height: 22),
            Container(
              width: 56,
              height: 2,
              color: PosterColors.ink.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(
              'One promise. One person keeping you to it.',
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 15.5,
                height: 1.4,
                color: PosterColors.ink.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: <Widget>[
                const PosterLabel('Swipe', size: 9, tracking: 2.2),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 1,
                    color: PosterColors.ink.withValues(alpha: 0.3),
                  ),
                ),
                const SizedBox(width: 12),
                const PosterLabel('(002)', size: 9),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePage extends StatelessWidget {
  const _RolePage({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return PosterField(
      tone: PosterTone.cream,
      child: Builder(
        builder: (context) {
          final style = PosterStyle.of(context);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PosterTopBar(
                  right: '(002)',
                  trailing: VouchAvatar(
                    name: auth.displayName,
                    photoUrl: auth.photoUrl,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 40),
                const PosterHeadline('Which\nside?', size: 50, accentTail: 1),
                const SizedBox(height: 12),
                Text(
                  'Two people. One promise. Pick the part you play.',
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 14,
                    height: 1.45,
                    color: style.muted,
                  ),
                ),
                const SizedBox(height: 26),
                _RoleCard(
                  number: '01',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreateTrackScreen(),
                    ),
                  ),
                  background: PosterColors.cobalt,
                  foreground: PosterColors.cream,
                  accent: PosterColors.acid,
                  accentForeground: PosterColors.ink,
                  title: 'I’m promising',
                  body: 'Create the promise.',
                ),
                const SizedBox(height: 12),
                _RoleCard(
                  number: '02',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const JoinTrackScreen(),
                    ),
                  ),
                  background: PosterColors.butter,
                  foreground: PosterColors.ink,
                  accent: PosterColors.coral,
                  accentForeground: PosterColors.cream,
                  title: 'I’m witnessing',
                  body: 'Join with a code.',
                ),
                const SizedBox(height: 30),
                const PosterFooter(
                  lead: 'Vouch',
                  muted: 'One promise. One witness.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.number,
    required this.onTap,
    required this.background,
    required this.foreground,
    required this.accent,
    required this.accentForeground,
    required this.title,
    required this.body,
  });

  final String number;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final Color accent;
  final Color accentForeground;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return PressableSpring(
      onTap: onTap,
      pressedScale: 0.975,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  '($number)',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: foreground.withValues(alpha: 0.6),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    color: accentForeground,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 0.95,
                letterSpacing: -1.3,
                color: foreground,
                fontVariations: const <FontVariation>[
                  FontVariation('wght', 700),
                  FontVariation('wdth', 94),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 13,
                height: 1.3,
                color: foreground.withValues(alpha: 0.66),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
