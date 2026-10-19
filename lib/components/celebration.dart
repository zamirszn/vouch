/// A short confetti celebration after a promise is marked kept.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/widgets.dart';

import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import 'glass_card.dart';
import 'vouch_button.dart';
import 'vouch_icon.dart';

Future<void> showCelebration(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Celebration',
    barrierColor: const Color(0xB3000000),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, animation, secondaryAnimation) {
      return CelebrationOverlay(title: title, message: message);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        return FadeTransition(opacity: animation, child: child);
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(milliseconds: 1600),
  );
  Timer? _autoClose;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _confetti.play();
      _autoClose = Timer(const Duration(milliseconds: 2400), () {
        if (mounted) Navigator.of(context).maybePop();
      });
    });
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          blastDirection: -math.pi / 2,
          numberOfParticles: 22,
          emissionFrequency: 0.06,
          maxBlastForce: 26,
          minBlastForce: 8,
          gravity: 0.16,
          colors: <Color>[
            theme.accent,
            theme.pending,
            theme.missed,
            theme.kept,
            VouchColors.paper,
          ],
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: GlassCard(
                radius: VouchRadius.large,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                glow: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 78,
                      height: 78,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.accent,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: theme.accent.withValues(alpha: 0.32),
                            blurRadius: 34,
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      child: VouchIcon(
                        VouchGlyph.check,
                        size: 40,
                        color: VouchColors.paperInk,
                        strokeWidth: 2.2,
                      ),
                    ),
                    const SizedBox(height: VouchSpace.x5),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: VouchType.display(theme.ink).copyWith(
                        fontSize: 30,
                        height: 0.98,
                      ),
                    ),
                    const SizedBox(height: VouchSpace.x2),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: VouchType.caption(theme.muted).copyWith(
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: VouchSpace.x5),
                    VouchButton(
                      label: 'Keep going',
                      expand: true,
                      onPressed: () =>
                          Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
