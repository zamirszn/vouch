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
import '../widgets/soul.dart';
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

    return TopFade(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 118),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PageHeader(
              eyebrow: 'History',
              title: 'The',
              titleMuted: 'record.',
              index: '(002)',
              subtitle: 'No edits. Just the days.',
            ),
            const SizedBox(height: 24),
            InkCard(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              monthLabel(month),
                              style: text.displaySmall?.copyWith(
                                fontSize: 28,
                                height: 1.05,
                                letterSpacing: -0.7,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$monthKept kept · $monthMissed missed',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton.outlined(
                      onPressed: canPrev
                          ? () => _shift(controller, -1)
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 19),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      onPressed: canNext
                          ? () => _shift(controller, 1)
                          : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 19),
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
                      color: VouchColors.kept,
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
            index: '01',
            title: 'Since the beginning',
          ),
          InkCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _HistoryStat(
                    value: '${stats.currentStreak}',
                    label: 'Current streak',
                    color: VouchColors.indigo,
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
                Expanded(
                  child: _HistoryStat(
                    value: '${stats.completed}',
                    label: 'Days kept',
                    color: VouchColors.keptDeep,
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
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
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            index: '02',
            title: 'Recent days',
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
    final dark = scheme.brightness == Brightness.dark;
    final shown = dark ? Color.lerp(color, Colors.white, 0.42)! : color;

    return Column(
      children: <Widget>[
        Text(
          value,
          style: text.displaySmall?.copyWith(
            color: shown,
            fontSize: 30,
            height: 1,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: text.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
            fontSize: 10,
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.10),
                  ),
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
