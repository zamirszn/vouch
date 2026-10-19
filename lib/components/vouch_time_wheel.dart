/// Custom reminder-time picker: two snapping reels and a meridiem toggle.
/// There is no showTimePicker anywhere in Vouch.
library;

import 'package:flutter/widgets.dart';

import '../design/vouch_motion.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import 'pressable.dart';
import 'vouch_button.dart';
import 'vouch_icon.dart';
import 'vouch_sheet.dart';

/// Opens the reels and returns the chosen 24-hour time, or null if dismissed.
Future<({int hour, int minute})?> showVouchTimeWheel(
  BuildContext context, {
  required int hour,
  required int minute,
}) {
  return showVouchPanel<({int hour, int minute})>(
    context,
    (_) => _TimeWheelPanel(hour: hour, minute: minute),
  );
}

String vouchClockLabel(int hour, int minute) {
  final safeHour = hour % 24;
  final suffix = safeHour >= 12 ? 'PM' : 'AM';
  final displayHour = safeHour % 12 == 0 ? 12 : safeHour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
}

class _TimeWheelPanel extends StatefulWidget {
  const _TimeWheelPanel({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  State<_TimeWheelPanel> createState() => _TimeWheelPanelState();
}

class _TimeWheelPanelState extends State<_TimeWheelPanel> {
  static const double _itemExtent = 44;

  late int _hour12;
  late int _minute;
  late bool _pm;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final safeHour = widget.hour % 24;
    _hour12 = safeHour % 12 == 0 ? 12 : safeHour % 12;
    _pm = safeHour >= 12;
    _minute = widget.minute;
    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  int get _hour24 {
    if (_hour12 == 12) return _pm ? 12 : 0;
    return _pm ? _hour12 + 12 : _hour12;
  }

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);

    return VouchSheet(
      title: 'Reminder time',
      subtitle: 'Both phones buzz at this hour.',
      child: Column(
        children: <Widget>[
          Text(
            vouchClockLabel(_hour24, _minute),
            style: VouchType.hero(theme.ink).copyWith(
              fontSize: 46,
              height: 1,
              letterSpacing: -1.6,
            ),
          ),
          const SizedBox(height: VouchSpace.x2),
          Text(
            'BOTH PHONES · SAME MOMENT',
            style: VouchType.label(theme.faint, size: 8.5),
          ),
          const SizedBox(height: VouchSpace.x4),
          Row(
            children: <Widget>[
              Expanded(
                flex: 5,
                child: _ReelLabel('HOUR'),
              ),
              const SizedBox(width: VouchSpace.x2),
              Expanded(
                flex: 5,
                child: _ReelLabel('MINUTE'),
              ),
              const SizedBox(width: VouchSpace.x5),
              const SizedBox(width: 72),
            ],
          ),
          const SizedBox(height: VouchSpace.x2),
          SizedBox(
            height: _itemExtent * 3,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                IgnorePointer(
                  child: Container(
                    height: _itemExtent,
                    decoration: BoxDecoration(
                      color: theme.glassStrong,
                      borderRadius:
                          BorderRadius.circular(VouchRadius.small),
                      border: Border.symmetric(
                        horizontal: BorderSide(color: theme.line),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      flex: 5,
                      child: _Reel(
                        controller: _hourController,
                        count: 12,
                        selected: _hour12 - 1,
                        label: (index) => '${index + 1}',
                        onChanged: (index) =>
                            setState(() => _hour12 = index + 1),
                      ),
                    ),
                    const SizedBox(width: VouchSpace.x2),
                    Expanded(
                      flex: 5,
                      child: _Reel(
                        controller: _minuteController,
                        count: 60,
                        selected: _minute,
                        label: (index) =>
                            index.toString().padLeft(2, '0'),
                        onChanged: (index) =>
                            setState(() => _minute = index),
                      ),
                    ),
                    const SizedBox(width: VouchSpace.x5),
                    SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _MeridiemPill(
                            label: 'AM',
                            selected: !_pm,
                            onTap: () => setState(() => _pm = false),
                          ),
                          const SizedBox(height: 6),
                          _MeridiemPill(
                            label: 'PM',
                            selected: _pm,
                            onTap: () => setState(() => _pm = true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VouchSpace.x4),
          VouchButton(
            label: 'Set time',
            expand: true,
            glyph: VouchGlyph.check,
            onPressed: () => Navigator.of(context)
                .pop((hour: _hour24, minute: _minute)),
          ),
        ],
      ),
    );
  }
}

class _ReelLabel extends StatelessWidget {
  const _ReelLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Center(
      child: Text(label, style: VouchType.label(theme.muted, size: 8.5)),
    );
  }
}

class _Reel extends StatelessWidget {
  const _Reel({
    required this.controller,
    required this.count,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int count;
  final int selected;
  final String Function(int index) label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final reduce = VouchMotion.reduced(context);

    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _TimeWheelPanelState._itemExtent,
      diameterRatio: 1.7,
      perspective: 0.002,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          final active = index == selected;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              style: VouchType.title(
                active ? theme.ink : theme.faint,
              ).copyWith(
                fontSize: 26,
                height: 1,
                letterSpacing: -0.4,
              ),
              child: Text(label(index)),
            ),
          );
        },
      ),
    );
  }
}

class _MeridiemPill extends StatelessWidget {
  const _MeridiemPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Pressable(
      onTap: onTap,
      scale: 0.95,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? theme.ink : theme.glass,
          borderRadius: BorderRadius.circular(VouchRadius.pill),
          border: Border.all(
            color: selected ? theme.ink : theme.line,
          ),
        ),
        child: Text(
          label,
          style: VouchType.label(
            selected ? theme.canvas : theme.muted,
            size: 10,
          ),
        ),
      ),
    );
  }
}
