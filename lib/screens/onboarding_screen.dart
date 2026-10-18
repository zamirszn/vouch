/// Choose: owner creating a promise, or partner joining one.
///
/// Page one is a full-bleed acid poster; page two is the printed choice sheet.
library;

import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import '../theme/vouch_theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/pressable_spring.dart';
import '../widgets/soul.dart';
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
      decoration: BoxDecoration(
        color: VouchColors.ink,
        shape: BoxShape.circle,
        border: Border.all(color: VouchColors.ink, width: 1.2),
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: page == 0 ? VouchColors.lime : VouchColors.cream,
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
    final text = Theme.of(context).textTheme;

    return ColoredBox(
      color: VouchColors.lime,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: IgnorePointer(
              child: _AcidGrid(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const BrandMark(
                        size: 40,
                        animate: false,
                        showShadow: false,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Vouch',
                        style: text.titleLarge?.copyWith(
                          color: VouchColors.ink,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '(001)',
                        style: text.labelSmall?.copyWith(
                          color: VouchColors.limeDeep,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      VouchAvatar(
                        name: auth.displayName,
                        photoUrl: auth.photoUrl,
                        size: 38,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        color: VouchColors.ink,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'A SMALL DEAL',
                        style: text.labelSmall?.copyWith(
                          color: VouchColors.limeDeep,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Make a promise.',
                    style: text.displayLarge?.copyWith(
                      color: VouchColors.ink,
                      fontSize: 52,
                      height: 0.9,
                      letterSpacing: -2.8,
                    ),
                  ),
                  Text(
                    'Name a witness.',
                    style: text.displayLarge?.copyWith(
                      color: VouchColors.limeDeep.withValues(alpha: 0.75),
                      fontSize: 52,
                      height: 0.9,
                      letterSpacing: -2.8,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: 64,
                    height: 2,
                    color: VouchColors.ink.withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'One promise. One person keeping you to it.',
                    style: text.bodyLarge?.copyWith(
                      color: VouchColors.limeDeep,
                      height: 1.45,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 42),
                  Row(
                    children: <Widget>[
                      Text(
                        'SWIPE',
                        style: text.labelSmall?.copyWith(
                          color: VouchColors.limeDeep,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: VouchColors.ink.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '(002)',
                        style: text.labelSmall?.copyWith(
                          color: VouchColors.limeDeep,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcidGrid extends StatelessWidget {
  const _AcidGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AcidGridPainter(),
      size: Size.infinite,
    );
  }
}

class _AcidGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = VouchColors.ink.withValues(alpha: 0.09)
      ..strokeWidth = 0.8;
    for (var x = 0.0; x < size.width; x += 22) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_AcidGridPainter oldDelegate) => false;
}

class _RolePage extends StatelessWidget {
  const _RolePage({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: GraphPaper(spacing: 22, alpha: 0.06)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const BrandMark(
                        size: 40,
                        animate: false,
                        showShadow: false,
                      ),
                      const SizedBox(width: 10),
                      Text('Vouch', style: text.titleLarge),
                      const Spacer(),
                      Text(
                        '(002)',
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      VouchAvatar(
                        name: auth.displayName,
                        photoUrl: auth.photoUrl,
                        size: 38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 42),
                  Text(
                    'Which',
                    style: text.displayLarge?.copyWith(
                      fontSize: 50,
                      height: 0.9,
                      letterSpacing: -2.6,
                    ),
                  ),
                  Text(
                    'side?',
                    style: text.displayLarge?.copyWith(
                      fontSize: 50,
                      height: 0.9,
                      letterSpacing: -2.6,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontVariations: const <FontVariation>[
                        FontVariation('wght', 500),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Two people. One promise. Pick the part you play.',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
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
                    background: VouchColors.ink,
                    foreground: VouchColors.cream,
                    accent: VouchColors.lime,
                    title: 'I’m promising',
                    body: 'Create the promise.',
                  ),
                  const SizedBox(height: 14),
                  _RoleCard(
                    number: '02',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const JoinTrackScreen(),
                      ),
                    ),
                    background: VouchColors.cream,
                    foreground: scheme.onSurface,
                    accent: VouchColors.coral,
                    title: 'I’m witnessing',
                    body: 'Join with a code.',
                    outlined: true,
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: <Widget>[
                      Text(
                        'VOUCH / MMXXVI',
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: scheme.onSurface.withValues(alpha: 0.18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
    required this.title,
    required this.body,
    this.outlined = false,
  });

  final String number;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final Color accent;
  final String title;
  final String body;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return PressableSpring(
      onTap: onTap,
      pressedScale: 0.975,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: outlined
              ? Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.22),
                  width: 1.2,
                )
              : null,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.16),
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  '($number)',
                  style: text.labelSmall?.copyWith(
                    color: foreground.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    color: VouchColors.ink,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              title,
              style: text.headlineLarge?.copyWith(
                color: foreground,
                fontSize: 31,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: text.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
