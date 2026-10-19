/// The record, printed on sage: a month of measured cells, lifetime counts
/// and the recent ledger. No edits — just the days.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/date_utils.dart';
import '../models/day_entry.dart';
import '../state/track_controller.dart';
import '../widgets/calendar_heatmap.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/poster.dart';
import '../widgets/soul.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? _month;

  DateTime _monthFor(DateTime today) =>
      _month ?? DateTime(today.year, today.month);

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
    final style = PosterStyle.of(context);
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
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          114 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PosterTopBar(
              right:
                  '${DateFormat('MMM yyyy').format(today).toUpperCase()} / (002)',
            ),
            const SizedBox(height: 28),
            PosterHeadline(
              'The\nrecord.',
              size: 50,
              accentTail: 1,
            ),
            const SizedBox(height: 10),
            Text(
              'Every mark, every miss. No edits.',
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 13,
                height: 1.35,
                color: style.muted,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: PosterStatCard(
                    value: '${stats.currentStreak}',
                    label: 'current streak',
                    color: PosterColors.acid,
                    foreground: PosterColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PosterStatCard(
                    value: '${stats.completed}',
                    label: 'days kept',
                    color: PosterColors.kelly,
                    foreground: PosterColors.cream,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PosterStatCard(
                    value: stats.elapsed == 0
                        ? '—'
                        : '${stats.completionPercent}%',
                    label: 'kept rate',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const PosterSectionLabel('01', 'the month'),
            const SizedBox(height: 10),
            PosterCard(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              monthLabel(month),
                              style: TextStyle(
                                fontFamily: 'InstrumentSans',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                                letterSpacing: -0.8,
                                color: style.cardInk,
                                fontVariations: const <FontVariation>[
                                  FontVariation('wght', 700),
                                  FontVariation('wdth', 96),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$monthKept kept · $monthMissed missed',
                              style: TextStyle(
                                fontFamily: 'InstrumentSans',
                                fontSize: 11.5,
                                color: style.cardMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _NavButton(
                        icon: Icons.arrow_back_rounded,
                        enabled: canPrev,
                        onTap: () => _shift(controller, -1),
                      ),
                      const SizedBox(width: 7),
                      _NavButton(
                        icon: Icons.arrow_forward_rounded,
                        enabled: canNext,
                        onTap: () => _shift(controller, 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: CalendarHeatmap(
                        key: ValueKey<String>('${month.year}-${month.month}'),
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
                    alignment: WrapAlignment.start,
                    spacing: 14,
                    runSpacing: 8,
                    children: <Widget>[
                      _LegendDot(
                        color: PosterColors.kelly,
                        label: 'Kept',
                        ink: style.cardMuted,
                      ),
                      _LegendDot(
                        color: PosterColors.coral,
                        label: 'Missed',
                        ink: style.cardMuted,
                      ),
                      _LegendDot(
                        color: PosterColors.cobalt,
                        label: 'Waiting',
                        ink: style.cardMuted,
                      ),
                      _LegendDot(
                        color: style.cardInk.withValues(alpha: 0.22),
                        label: 'Rest',
                        ink: style.cardMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const PosterSectionLabel('02', 'recent days'),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              PosterCard(
                child: Text(
                  'No days have been marked yet. Today is a good first one.',
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 13.5,
                    height: 1.4,
                    color: style.cardMuted,
                  ),
                ),
              )
            else
              PosterCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
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
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: style.line,
                        ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 26),
            PosterFooter(
              lead: 'Vouch',
              muted: '${stats.completed} days kept, on the record.',
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.28,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: style.cardInk,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 17, color: style.card),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.ink,
  });

  final Color color;
  final String label;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'InstrumentSans',
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: ink,
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
    final style = PosterStyle.of(context);
    final date = parseDayKey(entry.date);
    final completed = state == VouchDayState.completed;
    final color = completed ? PosterColors.kelly : PosterColors.coral;
    final note = (entry.note?.trim().isNotEmpty ?? false)
        ? entry.note!.trim()
        : (entry.partnerNote?.trim().isNotEmpty ?? false)
            ? entry.partnerNote!.trim()
            : 'No note.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      DateFormat('MMM').format(date).toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 7.5,
                        letterSpacing: 0.8,
                        color: PosterColors.cream,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: const TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: PosterColors.cream,
                        fontVariations: <FontVariation>[
                          FontVariation('wght', 700),
                        ],
                      ),
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
                      DateFormat('EEE d MMM').format(date),
                      style: TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: style.cardInk,
                        fontVariations: const <FontVariation>[
                          FontVariation('wght', 600),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 12,
                        color: style.cardMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PosterTag(
                completed ? 'kept' : 'missed',
                color: color.withValues(alpha: 0.13),
                foreground: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
