/// Motion tokens. Every animation in the app names one of these, so timing
/// feels consistent and reduced-motion is decided in one place.
library;

import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

abstract final class VouchMotion {
  /// Sections and cards arriving. Slow, soft, no overshoot.
  static const Motion enter = Motion.smoothSpring(
    duration: Duration(milliseconds: 620),
  );

  /// A card or section arriving after a shorter distance.
  static const Motion enterFast = Motion.snappySpring(
    duration: Duration(milliseconds: 380),
  );

  /// Dismissals and tab changes.
  static const Motion exit = Motion.snappySpring(
    duration: Duration(milliseconds: 300),
  );

  /// Finger down on any tappable surface.
  static const Motion press = Motion.snappySpring(
    duration: Duration(milliseconds: 200),
    extraBounce: 0,
  );

  /// Finger up; a little life on release.
  static const Motion release = Motion.bouncySpring(
    duration: Duration(milliseconds: 520),
    extraBounce: 0.06,
  );

  /// Counters, streak numbers, progress rulers.
  static const Motion value = Motion.smoothSpring(
    duration: Duration(milliseconds: 900),
  );

  /// Drag release and paging.
  static const Motion drag = Motion.interactiveSpring();

  /// Scroll-linked parallax and scaling.
  static const Motion scroll = Motion.smoothSpring(
    duration: Duration(milliseconds: 260),
  );

  /// Opacity fades must not overshoot; use curves, never springs.
  static const Motion fade = Motion.curved(
    Duration(milliseconds: 320),
    Curves.easeOutCubic,
  );

  /// The slow breathing loop behind surfaces.
  static const Motion ambient = Motion.curved(
    Duration(milliseconds: 3400),
    Curves.easeInOut,
  );

  /// Continuous rotation (loader).
  static const Motion spin = Motion.linear(Duration(milliseconds: 1400));

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Returns [motion], or a completed instant motion when the user has asked
  /// the system to reduce animation.
  static Motion resolve(BuildContext context, Motion motion) =>
      reduced(context) ? const Motion.none() : motion;
}
