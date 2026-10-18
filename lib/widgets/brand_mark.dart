/// The Vouch mark: a cream cookie with an indigo check, drawn with expressive
/// shapes so it can morph during entrances.
library;

import 'package:expressive_m3/expressive_m3.dart';
import 'package:flutter/material.dart';

import '../theme/vouch_theme.dart';

class BrandMark extends StatefulWidget {
  const BrandMark({
    super.key,
    this.size = 96,
    this.animate = true,
    this.showShadow = true,
  });

  final double size;
  final bool animate;
  final bool showShadow;

  @override
  State<BrandMark> createState() => _BrandMarkState();
}

class _BrandMarkState extends State<BrandMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = reduced ? 1.0 : Curves.easeOutCubic.transform(_controller.value);
        final scale = reduced ? 1.0 : 0.82 + 0.18 * t;
        final morph = reduced
            ? 1.0
            : Curves.easeOutBack.transform(t).clamp(0.0, 1.0).toDouble();

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: widget.showShadow
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: VouchColors.indigo.withValues(alpha: 0.22),
                        blurRadius: widget.size * 0.28,
                        offset: Offset(0, widget.size * 0.10),
                      ),
                    ],
                  )
                : null,
            child: ShapeClip(
              shape: ExpressiveShape.cookie,
              from: ExpressiveShape.circle,
              t: morph,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[VouchColors.indigo, Color(0xFF2A1E7A)],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: VouchColors.cream,
                    size: widget.size * 0.52,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
