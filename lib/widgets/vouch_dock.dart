/// The floating navigation dock: a printed paper bar with one black pill that
/// glides between tabs. Icons switch to acid inside the pill.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/vouch_theme.dart';

class VouchDock extends StatelessWidget {
  const VouchDock({
    super.key,
    required this.index,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<int> onSelected;

  static const List<(IconData, IconData, String)> _items =
      <(IconData, IconData, String)>[
    (Icons.bolt_outlined, Icons.bolt_rounded, 'Today'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'History'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottomInset + 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 82,
            decoration: BoxDecoration(
              color: (dark ? scheme.surfaceContainerHigh : VouchColors.cream)
                  .withValues(alpha: dark ? 0.86 : 0.9),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: scheme.onSurface.withValues(
                  alpha: dark ? 0.22 : 0.16,
                ),
                width: 1.2,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: dark ? 0.4 : 0.12),
                  offset: const Offset(0, 6),
                  blurRadius: 22,
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _items.length;
                const bubbleWidth = 62.0;
                const bubbleHeight = 34.0;

                return Stack(
                  children: <Widget>[
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 460),
                      curve: Curves.easeOutBack,
                      left: itemWidth * index + (itemWidth - bubbleWidth) / 2,
                      top: 13,
                      width: bubbleWidth,
                      height: bubbleHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: dark ? VouchColors.cream : VouchColors.ink,
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                    Row(
                      children: <Widget>[
                        for (var i = 0; i < _items.length; i++)
                          Expanded(
                            child: _DockItem(
                              icon: _items[i].$1,
                              selectedIcon: _items[i].$2,
                              label: _items[i].$3,
                              selected: index == i,
                              onTap: () => onSelected(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dark = scheme.brightness == Brightness.dark;
    final active = dark ? VouchColors.ink : VouchColors.lime;
    final foreground = selected ? active : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 44,
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  scale: selected ? 1.04 : 1,
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 21,
                    color: foreground,
                  ),
                ),
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              style: text.labelSmall!.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontSize: 9.5,
                letterSpacing: 1.1,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
