/// Month calendar, lifetime stats and the recent record.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../models/day_entry.dart';
import '../state/track_controller.dart';
import '../theme/vouch_theme.dart';
import '../widgets/calendar_heatmap.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/section_header.dart';
import '../widgets/status_pill.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _month;

  DateTime _monthFor(DateTime today) => _month ?? DateTime(today.year, today.month);

  DateTime _minMonth(DateTime today, DateTime? startedAt) {
    final windowStart = dateAt(today, -VouchConfig.historyWindowDays);
    var start = startedAt == null ? windowStart : dateOnly(startedAt);
    if (start.isBefore(windowStart)) start = windowStart;
    return DateTime(start.year, start.month);
  }

  void _shift(TrackController controller, int delta) {
    final current = _monthFor(controller.today);
    final target = DateTime(current.year, current.month + delta);
    final min = _minMonth(controller.today, controller.track?.startedAt);
    final max = DateTime(controller.today.year, controller.today.month);
    if (target.isBefore(min) || target.isAfter(max)) return;
    setState(() => _month = target);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrackController>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final track = controller.track;
    final today = controller.today;
    final month = _monthFor(today);
    final min = _minMonth(today, track?.startedAt);
    final max = DateTime(today.year, today.month);
    final canPrev = month.isAfter(min);
    final canNext = month.isBefore(max);
    final stats = controller.stats;

    final monthDays = <DateTime>[
      for (var day = 1;
          day <= DateTime(month.year, month.month + 1, 0).day;
          day++)
        DateTime(month.year, month.month, day),
    ];
    var monthKept = 0;
    var monthMissed = 0;
    for (final date in monthDays) {
      final state = controller.dayState(date);
      if (state == VouchDayState.completed) monthKept++;
      if (state == VouchDayState.missed) monthMissed++;
    }

    final recent = controller.days.values
        .where((entry) => entry.isMarked)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 118),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('The record.', style: text.displaySmall),
          const SizedBox(height: 6),
          Text(
            'Every day you kept your word — and every day you didn’t. No editing the past, only learning from it.',
            style: text.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          ExpressiveCard(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: canPrev
                          ? () => _shift(controller, -1)
                          : null,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Text(
                            monthLabel(month),
                            style: text.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '$monthKept kept · $monthMissed missed',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: canNext
                          ? () => _shift(controller, 1)
                          : null,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: CalendarHeatmap(
                      key: ValueKey<String>(
                        '${month.year}-${month.month}',
                      ),
                      month: month,
                      days: controller.days,
                      schedule: track?.schedule,
                      today: today,
                      onDayTap: (date) => showDayDetailSheet(
                        context,
                        date: date,
                        entry: controller.days[dayKey(date)],
                        state: controller.dayState(date),
                        today: today,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: const <Widget>[
                    _LegendDot(
                      color: Color(0xFF7FCB32),
                      label: 'Kept',
                    ),
                    _LegendDot(color: VouchColors.coral, label: 'Missed'),
                    _LegendDot(color: VouchColors.indigo, label: 'Waiting'),
                    _LegendDot(color: VouchColors.mist, label: 'Rest'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Since the beginning',
            subtitle: 'Counted in the track’s timezone.',
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: _HistoryStat(
                  value: '${stats.currentStreak}',
                  label: 'Current streak',
                  color: VouchColors.indigo,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HistoryStat(
                  value: '${stats.bestStreak}',
                  label: 'Best streak',
                  color: const Color(0xFF4C7A16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HistoryStat(
                  value: stats.elapsed == 0
                      ? '—'
                      : '${stats.completionPercent}%',
                  label: 'Kept rate',
                  color: VouchColors.coral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _HistoryStat(
                  value: '${stats.completed}',
                  label: 'Days kept',
                  color: const Color(0xFF4C7A16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HistoryStat(
                  value: '${stats.missed}',
                  label: 'Days missed',
                  color: VouchColors.coral,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HistoryStat(
                  value: '${stats.elapsed}',
                  label: 'Days counted',
                  color: VouchColors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Recent days',
            subtitle: 'Only the last 120 days are kept on this phone.',
          ),
          if (recent.isEmpty)
            ExpressiveCard(
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.hourglass_empty_rounded,
                    color: VouchColors.mist,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No days have been marked yet. Today is a good first one.',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ExpressiveCard(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                children: <Widget>[
                  for (var i = 0; i < recent.length && i < 12; i++) ...<Widget>[
                    _RecentRow(
                      entry: recent[i],
                      state: controller.dayState(
                        parseDayKey(recent[i].date),
                      ),
                      onTap: () => showDayDetailSheet(
                        context,
                        date: parseDayKey(recent[i].date),
                        entry: recent[i],
                        state: controller.dayState(
                          parseDayKey(recent[i].date),
                        ),
                        today: today,
                      ),
                    ),
                    if (i < recent.length - 1 && i < 11)
                      const Divider(indent: 12, endIndent: 12),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: text.headlineSmall?.copyWith(color: color, fontSize: 25),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.entry,
    required this.state,
    required this.onTap,
  });

  final DayEntry entry;
  final VouchDayState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final date = parseDayKey(entry.date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      DateFormat('MMM').format(date).toUpperCase(),
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: text.titleSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      friendlyDay(date, today: DateTime.now()),
                      style: text.titleSmall,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      (entry.note?.trim().isNotEmpty ?? false)
                          ? entry.note!.trim()
                          : (entry.partnerNote?.trim().isNotEmpty ?? false)
                              ? entry.partnerNote!.trim()
                              : 'No note.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill.day(state, dense: true),
            ],
          ),
        ),
      ),
    );
  }
}
