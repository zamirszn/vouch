/// The floating navigation dock: the active tab sits on a tilted, colour-block
/// sticker.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: dark ? 0.72 : 0.78),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: scheme.onSurface.withValues(
                  alpha: dark ? 0.12 : 0.10,
                ),
                width: 1.2,
              ),
            ),
            child: Row(
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

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(26),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              width: 42,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                border: selected
                    ? Border.all(
                        color: scheme.onPrimary.withValues(alpha: 0.18),
                        width: 1.2,
                      )
                    : null,
              ),
              child: Transform.rotate(
                angle: selected ? -0.06 : 0,
                child: Icon(
                  selected ? selectedIcon : icon,
                  size: 22,
                  color: selected
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: text.labelSmall?.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontVariations: <FontVariation>[
                  FontVariation('wght', selected ? 800 : 600),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
