/// Shared motion tokens. All springs come from Material 3 Expressive.
library;

import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

class VouchMotion {
  const VouchMotion._();

  static const Motion spatialFast =
      MaterialSpringMotion.expressiveSpatialFast();
  static const Motion spatialDefault =
      MaterialSpringMotion.expressiveSpatialDefault();
  static const Motion spatialSlow =
      MaterialSpringMotion.expressiveSpatialSlow();
  static const Motion effectsFast =
      MaterialSpringMotion.expressiveEffectsFast();
  static const Motion effectsDefault =
      MaterialSpringMotion.expressiveEffectsDefault();
  static const Motion effectsSlow =
      MaterialSpringMotion.expressiveEffectsSlow();

  static const Duration quick = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 560);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration scaled(BuildContext context, Duration duration) =>
      reduced(context) ? const Duration(milliseconds: 1) : duration;
}
