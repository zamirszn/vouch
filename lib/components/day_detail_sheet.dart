/// Read-only detail for one calendar day.
library;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../core/date_utils.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import '../models/day_entry.dart';
import 'stat_tile.dart';
import 'vouch_icon.dart';
import 'vouch_sheet.dart';

Future<void> showDayDetailSheet(
  BuildContext context, {
  required DateTime date,
  required DayEntry? entry,
  required VouchDayState state,
  required DateTime today,
}) {
  return showVouchPanel<void>(
    context,
    (_) => DayDetailSheet(
      date: date,
      entry: entry,
      state: state,
      today: today,
    ),
  );
}

class DayDetailSheet extends StatelessWidget {
  const DayDetailSheet({
    super.key,
    required this.date,
    required this.entry,
    required this.state,
    required this.today,
  });

  final DateTime date;
  final DayEntry? entry;
  final VouchDayState state;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final day = entry;

    final (label, tone) = switch (state) {
      VouchDayState.completed => ('Kept', VouchTone.kept),
      VouchDayState.missed => ('Missed', VouchTone.missed),
      VouchDayState.pending => ('Awaiting the mark', VouchTone.pending),
      VouchDayState.upcoming => ('Upcoming', VouchTone.rest),
      VouchDayState.rest => ('Rest day', VouchTone.rest),
    };

    return VouchSheet(
      title: DateFormat('EEEE, d MMMM').format(date),
      subtitle: friendlyDay(date, today: today),
      leading: Container(
        width: 54,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.accent,
          borderRadius: BorderRadius.circular(VouchRadius.small),
        ),
        child: Text(
          '${date.day}',
          style: VouchType.title(VouchColors.paperInk)
              .copyWith(fontSize: 24, height: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StatusChip(label: label, tone: tone),
          const SizedBox(height: VouchSpace.x5),
          Text(
            'What you did',
            style: VouchType.bodyStrong(theme.ink).copyWith(fontSize: 14),
          ),
          const SizedBox(height: VouchSpace.x2),
          _Panel(
            child: Text(
              (day?.note?.trim().isNotEmpty ?? false)
                  ? day!.note!.trim()
                  : state == VouchDayState.rest
                      ? 'A rest day — no promise scheduled.'
                      : 'No note was written for this day.',
              style: VouchType.body(
                (day?.note?.trim().isNotEmpty ?? false)
                    ? theme.ink
                    : theme.faint,
              ).copyWith(
                fontSize: 13.5,
                height: 1.45,
                fontStyle: (day?.note?.trim().isNotEmpty ?? false)
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: VouchSpace.x5),
          Text(
            'Your partner',
            style: VouchType.bodyStrong(theme.ink).copyWith(fontSize: 14),
          ),
          const SizedBox(height: VouchSpace.x2),
          if (day == null || day.status == DayStatus.pending)
            _Panel(
              child: Row(
                children: <Widget>[
                  VouchIcon(
                    VouchGlyph.clock,
                    size: 16,
                    color: theme.muted,
                  ),
                  const SizedBox(width: VouchSpace.x3),
                  Expanded(
                    child: Text(
                      'Not marked yet.',
                      style: VouchType.caption(theme.muted)
                          .copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            _Panel(
              tint: day.status == DayStatus.completed
                  ? theme.kept
                  : theme.missed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      StatusChip(
                        label: day.status == DayStatus.completed
                            ? 'Kept'
                            : 'Missed',
                        tone: day.status == DayStatus.completed
                            ? VouchTone.kept
                            : VouchTone.missed,
                      ),
                      const Spacer(),
                      if (day.method != null)
                        Text(
                          day.method!.label,
                          style: VouchType.mono(theme.muted, size: 9.5),
                        ),
                    ],
                  ),
                  if (day.markedAt != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('h:mm a').format(day.markedAt!.toLocal()),
                      style: VouchType.caption(theme.faint)
                          .copyWith(fontSize: 11.5),
                    ),
                  ],
                  if (day.partnerNote?.trim().isNotEmpty ?? false) ...<Widget>[
                    const SizedBox(height: VouchSpace.x3),
                    Text(
                      '“${day.partnerNote!.trim()}”',
                      style: VouchType.body(theme.ink)
                          .copyWith(fontSize: 13.5, height: 1.45),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: VouchSpace.x5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              VouchIcon(VouchGlyph.calendar, size: 15, color: theme.faint),
              const SizedBox(width: VouchSpace.x2),
              Expanded(
                child: Text(
                  'Days with no mark become missed after midnight in the '
                  'track’s timezone. Rest days follow the partner’s '
                  'schedule.',
                  style: VouchType.caption(theme.faint)
                      .copyWith(fontSize: 11.5, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.tint});

  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint == null
            ? theme.glass
            : tint!.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(VouchRadius.small),
        border: Border.all(
          color: tint == null
              ? theme.line
              : tint!.withValues(alpha: 0.28),
        ),
      ),
      child: child,
    );
  }
}
