/// A short confetti celebration after a promise is marked kept.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import 'poster.dart';

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
            PosterColors.acid,
            PosterColors.cobalt,
            PosterColors.coral,
            PosterColors.kelly,
            PosterColors.cream,
          ],
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  color: PosterColors.ink,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: PosterColors.cream.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 78,
                      height: 78,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: PosterColors.acid,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: PosterColors.ink,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        height: 0.98,
                        letterSpacing: -1.2,
                        color: PosterColors.cream,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                          FontVariation('wdth', 94),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 13,
                        height: 1.45,
                        color: PosterColors.cream.withValues(alpha: 0.66),
                      ),
                    ),
                    const SizedBox(height: 22),
                    PosterPill(
                      label: 'Keep going',
                      height: 52,
                      onPressed: () => Navigator.of(context).maybePop(),
                      color: PosterColors.cream,
                      foreground: PosterColors.ink,
                      arrowColor: PosterColors.acid,
                      arrowForeground: PosterColors.ink,
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
