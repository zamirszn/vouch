/// The floating navigation dock: one black capsule, cream icons and an acid
/// lozenge that glides under the active tab. The posters' black-pill motif,
/// docked to the bottom of every screen.
library;

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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset + 14),
      child: Container(
        height: 66,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: VouchColors.ink,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: VouchColors.cream.withValues(alpha: 0.14),
            width: 1,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected
                ? VouchColors.acid
                : VouchColors.cream.withValues(alpha: 0.0),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                selected ? selectedIcon : icon,
                size: 20,
                color: selected
                    ? VouchColors.ink
                    : VouchColors.cream.withValues(alpha: 0.68),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'InstrumentSans',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  height: 1.1,
                  color: selected
                      ? VouchColors.ink
                      : VouchColors.cream.withValues(alpha: 0.68),
                  fontVariations: const <FontVariation>[
                    FontVariation('wght', 600),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
