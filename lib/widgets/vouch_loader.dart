/// The app's indeterminate progress indicator.
///
/// Material 3 Expressive replaces the plain circular spinner with a glyph that
/// morphs through the seven expressive shapes. Reduced-motion users see a
/// single static shape instead.
library;

import 'package:expressive_m3/expressive_m3.dart';
import 'package:flutter/material.dart';

class VouchLoader extends StatelessWidget {
  const VouchLoader({
    super.key,
    this.size = 48,
    this.color,
    this.contained = false,
  });

  final double size;
  final Color? color;
  final bool contained;

  @override
  Widget build(BuildContext context) {
    return ExpressiveLoadingIndicator(
      size: size,
      color: color,
      contained: contained,
    );
  }
}
