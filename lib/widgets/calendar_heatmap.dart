/// Month calendar with expressive day dots.
library;

import 'package:flutter/material.dart';

import '../core/date_utils.dart';
import '../models/day_entry.dart';
import '../models/schedule.dart';
import 'poster.dart';

class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({
    super.key,
    required this.month,
    required this.days,
    required this.schedule,
    required this.today,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<String, DayEntry> days;
  final VouchSchedule? schedule;
  final DateTime today;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday - DateTime.monday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: <Widget>[
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _cell(context, row * 7 + col - leading, daysInMonth),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int index, int daysInMonth) {
    if (index < 0 || index >= daysInMonth) {
      return const SizedBox(height: 44);
    }
    final date = DateTime(month.year, month.month, index + 1);
    final state = dayStateFor(
      schedule: schedule,
      entry: days[dayKey(date)],
      date: date,
      today: today,
    );
    final isToday = dateOnly(date) == dateOnly(today);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final (Color bg, Color fg) = switch (state) {
      VouchDayState.completed => (PosterColors.kelly, PosterColors.cream),
      VouchDayState.missed => (
        PosterColors.coral.withValues(alpha: 0.20),
        const Color(0xFF9E2B16),
      ),
      VouchDayState.pending => (
        PosterColors.cobalt.withValues(alpha: 0.14),
        PosterColors.cobalt,
      ),
      VouchDayState.rest => (
        Colors.transparent,
        scheme.onSurfaceVariant.withValues(alpha: 0.65),
      ),
      VouchDayState.upcoming => (
        Colors.transparent,
        scheme.onSurfaceVariant.withValues(alpha: 0.45),
      ),
    };

    return Center(
      child: GestureDetector(
        onTap: () => onDayTap(date),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: scheme.onSurface, width: 1.6)
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('${date.day}', style: text.labelMedium?.copyWith(color: fg)),
              if (state == VouchDayState.completed ||
                  state == VouchDayState.missed)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(color: fg.withValues(alpha: 0.75)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
