/// A short confetti celebration after a promise is marked kept.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/vouch_theme.dart';

Future<void> showCelebration(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Celebration',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, animation, secondaryAnimation) {
      return CelebrationOverlay(title: title, message: message);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

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
          colors: const <Color>[
            VouchColors.indigo,
            VouchColors.coral,
            VouchColors.lime,
            Color(0xFF7FCB32),
            VouchColors.cream,
          ],
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: <Color>[
                            Color(0xFF7FCB32),
                            Color(0xFF3E7A12),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: text.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Keep going'),
                      ),
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
