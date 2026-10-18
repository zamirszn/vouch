/// The Vouch mark: a flat ink disc, a cream check and one acid dot. Printed,
/// not glossy.
library;

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
    duration: const Duration(milliseconds: 700),
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
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? VouchColors.cream : VouchColors.ink;
    final paper = dark ? VouchColors.ink : VouchColors.cream;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = reduced
            ? 1.0
            : Curves.easeOutBack.transform(_controller.value).clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.86 + 0.14 * t,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: ink,
              shape: BoxShape.circle,
              boxShadow: widget.showShadow
                  ? <BoxShadow>[
                      BoxShadow(
                        color: VouchColors.coral.withValues(alpha: 0.9),
                        offset: Offset(widget.size * 0.05, widget.size * 0.05),
                        blurRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: <Widget>[
                Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: paper,
                    size: widget.size * 0.48,
                  ),
                ),
                Positioned(
                  top: widget.size * 0.16,
                  right: widget.size * 0.18,
                  child: Container(
                    width: widget.size * 0.16,
                    height: widget.size * 0.16,
                    decoration: const BoxDecoration(
                      color: VouchColors.lime,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
