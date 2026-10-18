/// Read-only detail for one calendar day.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/date_utils.dart';
import '../models/day_entry.dart';
import '../theme/vouch_theme.dart';
import 'note_editor_sheet.dart';
import 'sheet_frame.dart';
import 'status_pill.dart';

Future<void> showDayDetailSheet(
  BuildContext context, {
  required DateTime date,
  required DayEntry? entry,
  required VouchDayState state,
  required DateTime today,
}) {
  return showVouchSheet<void>(
    context,
    DayDetailSheet(
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final day = entry;

    return SheetFrame(
      title: DateFormat('EEEE, d MMMM').format(date),
      subtitle: friendlyDay(date, today: today),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: VouchColors.indigo.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: text.headlineSmall?.copyWith(color: VouchColors.indigo),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StatusPill.day(state),
          const SizedBox(height: 18),
          Text('What you did', style: text.titleSmall),
          const SizedBox(height: 8),
          NotePreview(
            note: day?.note,
            emptyLabel: state == VouchDayState.rest
                ? 'A rest day — no promise scheduled.'
                : 'No note was written for this day.',
          ),
          const SizedBox(height: 18),
          Text('Your partner', style: text.titleSmall),
          const SizedBox(height: 8),
          if (day == null || day.status == DayStatus.pending)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.schedule_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Not marked yet.',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: day.status == DayStatus.completed
                    ? const Color(0xFF7FCB32).withValues(alpha: 0.12)
                    : VouchColors.coral.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      StatusPill.mark(day.status, dense: true),
                      const Spacer(),
                      if (day.method != null)
                        Text(
                          day.method!.label,
                          style: text.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  if (day.markedAt != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('h:mm a').format(day.markedAt!.toLocal()),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (day.partnerNote?.trim().isNotEmpty ?? false) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      '“${day.partnerNote!.trim()}”',
                      style: text.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          const SheetNote(
            icon: Icons.calendar_month_outlined,
            text:
                'Days with no mark become missed after midnight in the track’s timezone. Rest days follow the partner’s schedule.',
          ),
        ],
      ),
    );
  }
}
