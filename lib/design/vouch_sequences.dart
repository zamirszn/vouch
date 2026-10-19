/// Named motor sequences shared by the component library.
library;

import 'package:flutter/animation.dart';
import 'package:motor/motor.dart';

import 'vouch_motion.dart';

/// Phases for a confirmation action: at rest, pressed, sealed.
enum SealPhase { idle, pressed, sealed }

/// Phases for inline validation feedback.
enum FeedbackPhase { idle, error, settle }

abstract final class VouchSequences {
  /// 0 → 1 → 0 forever. Drives aura opacity and glow scale.
  static final MotionSequence<int, double> breath = MotionSequence.steps<double>(
    const <double>[0, 1],
    motion: VouchMotion.ambient,
    loop: LoopMode.pingPong,
  );

  /// Continuous 0 → 1 rotation, used by [VouchLoader].
  static final MotionSequence<int, double> rotation =
      MotionSequence.steps<double>(
    const <double>[0, 1],
    motion: VouchMotion.spin,
    loop: LoopMode.seamless,
  );

  /// Press → seal → rest. Use with `SequenceMotionBuilder(playing: ...)`.
  static final MotionSequence<SealPhase, double> seal =
      MotionSequence.statesWithMotions(<SealPhase, (double, Motion)>{
    SealPhase.idle: (1, VouchMotion.enterFast),
    SealPhase.pressed: (0.86, VouchMotion.press),
    SealPhase.sealed: (1.06, VouchMotion.release),
  });

  /// A short horizontal shake: 0 → -1 → 1 → -0.5 → 0.
  static final MotionSequence<int, double> shake =
      MotionSequence.steps<double>(const <double>[
    0,
    -1,
    1,
    -0.55,
    0,
  ], motion: Motion.curved(const Duration(milliseconds: 90), Curves.easeInOut));

  /// The staggered reveal used when a screen first paints.
  static final MotionSequence<int, Offset> rise =
      MotionSequence.steps<Offset>(const <Offset>[
    Offset(0, 0.05),
    Offset.zero,
  ], motion: VouchMotion.enter);

  /// A single seal pop for celebratory moments.
  static final MotionSequence<int, double> pop = MotionSequence.steps<double>(
    const <double>[0, 1, 1.08, 1],
    motion: VouchMotion.release,
  );
}
