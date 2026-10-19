/// The record: a month of measured cells, lifetime counts and the recent
/// ledger. Read-only — the days are shown as they were marked.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../components/glass_card.dart';
import '../components/pressable.dart';
import '../components/reveal.dart';
import '../components/section_label.dart';
import '../components/stat_tile.dart';
import '../components/vouch_icon.dart';
import '../components/vouch_top_bar.dart';
import '../core/constants.dart';
import '../core/date_utils.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../models/day_entry.dart';
import '../models/schedule.dart';
import '../state/track_controller.dart';
import '../components/day_detail_sheet.dart';

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
    final theme = VouchScope.of(context);
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

    final rate = stats.elapsed == 0 ? '—' : '${stats.completionPercent}%';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          VouchSpace.gutter,
          VouchSpace.x2,
          VouchSpace.gutter,
          VouchSpace.navHeight +
              MediaQuery.viewPaddingOf(context).bottom +
              VouchSpace.x10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Reveal(
              index: 0,
              child: VouchTopBar(
                annotation:
                    '${DateFormat('MMM yyyy').format(today).toUpperCase()} / (002)',
              ),
            ),
            const SizedBox(height: VouchSpace.x6),
            Reveal(
              index: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'The\nrecord.',
                    style: VouchType.hero(theme.ink)
                        .copyWith(fontSize: 52, height: 0.92),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Every mark, every miss. No edits.',
                    style: VouchType.caption(theme.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VouchSpace.x6),
            Reveal(
              index: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: StatTile(
                      value: '${stats.currentStreak}',
                      label: 'streak',
                      tone: VouchTone.pending,
                      height: 96,
                    ),
                  ),
                  const SizedBox(width: VouchSpace.x2),
                  Expanded(
                    child: StatTile(
                      value: '${stats.completed}',
                      label: 'days kept',
                      tone: VouchTone.kept,
                      height: 96,
                    ),
                  ),
                  const SizedBox(width: VouchSpace.x2),
                  Expanded(
                    child: StatTile(
                      value: rate,
                      label: 'kept rate',
                      tone: VouchTone.rest,
                      height: 96,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VouchSpace.x6),
            Reveal(
              index: 3,
              child: SectionLabel(index: '01', title: 'the month'),
            ),
            const SizedBox(height: VouchSpace.x3),
            Reveal(
              index: 4,
              child: GlassCard(
                radius: VouchRadius.card,
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                monthLabel(month),
                                style: VouchType.cardTitle(theme.ink).copyWith(
                                  fontSize: 23,
                                  letterSpacing: -0.7,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$monthKept kept · $monthMissed missed',
                                style: VouchType.caption(theme.muted)
                                    .copyWith(fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        _MonthButton(
                          glyph: VouchGlyph.chevronLeft,
                          enabled: canPrev,
                          semanticLabel: 'Previous month',
                          onTap: () => _shift(controller, -1),
                        ),
                        const SizedBox(width: VouchSpace.x2),
                        _MonthButton(
                          glyph: VouchGlyph.chevronRight,
                          enabled: canNext,
                          semanticLabel: 'Next month',
                          onTap: () => _shift(controller, 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: VouchSpace.x4),
                    AnimatedSize(
                      duration: VouchDurations.base,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: VouchDurations.fast,
                        child: _MonthGrid(
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
                    const SizedBox(height: VouchSpace.x4),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: <Widget>[
                        _LegendDot(
                          color: theme.kept,
                          label: 'Kept',
                        ),
                        _LegendDot(
                          color: theme.missed,
                          label: 'Missed',
                        ),
                        _LegendDot(
                          color: theme.pending,
                          label: 'Waiting',
                        ),
                        _LegendDot(
                          color: theme.faint,
                          label: 'Rest',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: VouchSpace.x6),
            Reveal(
              index: 5,
              child: SectionLabel(
                index: '02',
                title: 'recent days',
                trailing: recent.isEmpty ? null : '${recent.length} marked',
              ),
            ),
            const SizedBox(height: VouchSpace.x3),
            Reveal(
              index: 6,
              child: recent.isEmpty
                  ? GlassCard(
                      radius: VouchRadius.card,
                      child: Text(
                        'No days have been marked yet. Today is a good first one.',
                        style: VouchType.caption(theme.muted).copyWith(
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                    )
                  : GlassCard(
                      radius: VouchRadius.card,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        children: <Widget>[
                          for (var i = 0;
                              i < recent.length && i < 12;
                              i++) ...<Widget>[
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
                              Padding(
                                padding: const EdgeInsets.only(left: 70),
                                child: Container(height: 1, color: theme.line),
                              ),
                          ],
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: VouchSpace.x6),
            Container(height: 1, color: theme.line),
            const SizedBox(height: VouchSpace.x4),
            Text('Vouch', style: VouchType.body(theme.muted)),
            const SizedBox(height: 4),
            Text(
              '${stats.completed} days kept, on the record.',
              style: VouchType.caption(theme.faint),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The month
// ---------------------------------------------------------------------------

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.glyph,
    required this.enabled,
    required this.semanticLabel,
    required this.onTap,
  });

  final VouchGlyph glyph;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Opacity(
      opacity: enabled ? 1 : 0.26,
      child: Pressable(
        haptic: false,
        semanticLabel: semanticLabel,
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.glassStrong,
            border: Border.all(color: theme.line, width: 1),
          ),
          child: VouchIcon(glyph, size: 15, color: theme.ink),
        ),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
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
    final theme = VouchScope.of(context);
    final first = DateTime(month.year, month.month, 1);
    final leading = first.weekday - DateTime.monday;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((leading + daysInMonth) / 7).ceil();

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    const <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                    style: VouchType.label(theme.faint, size: 8.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: VouchSpace.x2),
        for (var row = 0; row < rows; row++)
          Row(
            children: <Widget>[
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _DayCell(
                    date: DateTime(month.year, month.month, row * 7 + col -
                        leading + 1),
                    index: row * 7 + col - leading,
                    daysInMonth: daysInMonth,
                    days: days,
                    schedule: schedule,
                    today: today,
                    onTap: onDayTap,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.index,
    required this.daysInMonth,
    required this.days,
    required this.schedule,
    required this.today,
    required this.onTap,
  });

  final DateTime date;
  final int index;
  final int daysInMonth;
  final Map<String, DayEntry> days;
  final VouchSchedule? schedule;
  final DateTime today;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    if (index < 0 || index >= daysInMonth) {
      return const SizedBox(height: 40);
    }

    final state = dayStateFor(
      schedule: schedule,
      entry: days[dayKey(date)],
      date: date,
      today: today,
    );
    final accent = toneColor(context, toneForDay(state));
    final isToday = dateOnly(date) == dateOnly(today);

    final (Color fill, Color ink) = switch (state) {
      VouchDayState.completed => (accent, VouchColors.paperInk),
      VouchDayState.missed => (accent.withValues(alpha: 0.16), accent),
      VouchDayState.pending => (accent.withValues(alpha: 0.13), accent),
      VouchDayState.rest => (const Color(0x00000000), theme.faint),
      VouchDayState.upcoming =>
        (const Color(0x00000000), theme.faint.withValues(alpha: 0.5)),
    };
    final showDot = state == VouchDayState.completed ||
        state == VouchDayState.missed ||
        state == VouchDayState.pending;

    return Pressable(
      haptic: false,
      semanticLabel: '${DateFormat('d MMMM').format(date)}, ${_stateLabel(state)}',
      onTap: () => onTap(date),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1.5),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: isToday
                  ? theme.ink
                  : state == VouchDayState.pending
                      ? accent.withValues(alpha: 0.32)
                      : const Color(0x00000000),
              width: isToday ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${date.day}',
                style: VouchType.mono(ink, size: 11.5).copyWith(height: 1.05),
              ),
              const SizedBox(height: 3),
              Container(
                width: 3.5,
                height: 3.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: showDot
                      ? ink.withValues(alpha: 0.8)
                      : const Color(0x00000000),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _stateLabel(VouchDayState state) => switch (state) {
      VouchDayState.completed => 'kept',
      VouchDayState.missed => 'missed',
      VouchDayState.pending => 'waiting to be marked',
      VouchDayState.rest => 'rest day',
      VouchDayState.upcoming => 'upcoming',
    };

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: VouchType.caption(theme.muted).copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// The recent ledger
// ---------------------------------------------------------------------------

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
    final theme = VouchScope.of(context);
    final date = parseDayKey(entry.date);
    final completed = state == VouchDayState.completed;
    final accent = completed ? theme.kept : theme.missed;
    final note = (entry.note?.trim().isNotEmpty ?? false)
        ? entry.note!.trim()
        : (entry.partnerNote?.trim().isNotEmpty ?? false)
            ? entry.partnerNote!.trim()
            : 'No note.';

    return Pressable(
      haptic: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(VouchRadius.small),
                border: Border.all(
                  color: accent.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    DateFormat('MMM').format(date).toUpperCase(),
                    style: VouchType.label(accent, size: 7.5),
                  ),
                  Text(
                    '${date.day}',
                    style: VouchType.numeral(theme.ink, size: 18).copyWith(
                      height: 1.1,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: VouchSpace.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    DateFormat('EEE d MMM').format(date),
                    style: VouchType.bodyStrong(theme.ink)
                        .copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VouchType.caption(theme.muted)
                        .copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: VouchSpace.x2),
            StatusChip(
              label: completed ? 'kept' : 'missed',
              tone: completed ? VouchTone.kept : VouchTone.missed,
            ),
          ],
        ),
      ),
    );
  }
}
