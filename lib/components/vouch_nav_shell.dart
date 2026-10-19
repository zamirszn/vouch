/// Flush, frosted bottom navigation. Replaces the old floating dock.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

import '../design/vouch_motion.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import 'pressable.dart';
import 'vouch_icon.dart';

class VouchNavItem {
  const VouchNavItem({
    required this.label,
    required this.glyph,
  });

  final String label;
  final VouchGlyph glyph;
}

class VouchNavShell extends StatelessWidget {
  const VouchNavShell({
    super.key,
    required this.index,
    required this.onSelect,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final List<VouchNavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final count = items.length;
    final target = index.clamp(0, count - 1).toDouble();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (theme.isDark ? const Color(0xFF08090B) : theme.canvas)
                .withValues(alpha: 0.74),
            border: Border(top: BorderSide(color: theme.line, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: VouchSpace.navHeight,
              child: Stack(
                children: <Widget>[
                  if (count > 1)
                    SingleMotionBuilder(
                      value: target,
                      motion: VouchMotion.resolve(context, VouchMotion.value),
                      from: target,
                      builder: (context, value, _) {
                        final fraction = (value + 0.5) / count;
                        final x = (fraction * 2 - 1).clamp(-1.0, 1.0);
                        return Align(
                          alignment: Alignment(x, 0),
                          child: Container(
                            width: 62,
                            height: 36,
                            decoration: BoxDecoration(
                              color: theme.isDark
                                  ? const Color(0x14FFFFFF)
                                  : const Color(0x0F000000),
                              borderRadius:
                                  BorderRadius.circular(VouchRadius.pill),
                              border: Border.all(color: theme.line),
                            ),
                          ),
                        );
                      },
                    ),
                  Row(
                    children: <Widget>[
                      for (var i = 0; i < count; i++)
                        Expanded(
                          child: _NavButton(
                            item: items[i],
                            selected: i == index,
                            onTap: () => onSelect(i),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final VouchNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: Pressable(
        onTap: onTap,
        scale: 0.9,
        haptic: false,
        child: Center(
          child: MotionBuilder<Color>(
            value: selected ? theme.ink : theme.faint,
            motion: VouchMotion.exit,
            converter: MotionConverter.colorRgb,
            builder: (context, color, child) => Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                VouchIcon(item.glyph, size: 21, color: color),
                const SizedBox(height: 4),
                Text(item.label, style: VouchType.nav.copyWith(color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
