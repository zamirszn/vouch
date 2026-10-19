/// Seven-day strip with state dots.
library;

import 'package:flutter/widgets.dart';

import '../core/date_utils.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_type.dart';
import 'pressable.dart';
import 'stat_tile.dart';

class WeekStripDay {
  const WeekStripDay({required this.date, required this.state});
  final DateTime date;
  final VouchDayState state;
}

class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.days,
    required this.today,
    this.onTap,
  });

  final List<WeekStripDay> days;
  final DateTime today;
  final ValueChanged<WeekStripDay>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final todayKeyValue = dayKey(today);
    return Row(
      children: <Widget>[
        for (final day in days)
          Expanded(
            child: Pressable(
              haptic: false,
              onTap: onTap == null ? null : () => onTap!(day),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: <Widget>[
                    Text(
                      _initial(day.date),
                      style: VouchType.label(theme.faint, size: 9),
                    ),
                    const SizedBox(height: 8),
                    _Dot(
                      state: day.state,
                      isToday: dayKey(day.date) == todayKeyValue,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${day.date.day}',
                      style: VouchType.mono(
                        dayKey(day.date) == todayKeyValue
                            ? theme.ink
                            : theme.faint,
                        size: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _initial(DateTime date) {
    const names = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return names[date.weekday - 1];
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.state, required this.isToday});

  final VouchDayState state;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final color = toneColor(context, toneForDay(state));
    final filled = state == VouchDayState.completed ||
        state == VouchDayState.missed;
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : color.withValues(alpha: 0.12),
        border: Border.all(
          color: isToday
              ? theme.ink
              : filled
                  ? color
                  : color.withValues(alpha: 0.35),
          width: isToday ? 1.6 : 1,
        ),
      ),
    );
  }
}
