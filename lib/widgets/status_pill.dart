/// Small rounded status label used for days, tracks and roles.
library;

import 'package:flutter/material.dart';

import '../core/date_utils.dart';
import '../models/day_entry.dart';
import '../theme/vouch_theme.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  factory StatusPill.day(
    VouchDayState state, {
    bool dense = false,
  }) {
    return switch (state) {
      VouchDayState.completed => StatusPill(
          label: 'Kept',
          color: const Color(0xFF3E7A12),
          icon: Icons.check_rounded,
          dense: dense,
        ),
      VouchDayState.missed => const StatusPill(
          label: 'Missed',
          color: Color(0xFFB3261E),
          icon: Icons.close_rounded,
        ),
      VouchDayState.pending => const StatusPill(
          label: 'Waiting',
          color: VouchColors.indigo,
          icon: Icons.schedule_rounded,
        ),
      VouchDayState.rest => const StatusPill(
          label: 'Rest',
          color: VouchColors.mist,
          icon: Icons.bedtime_outlined,
        ),
      VouchDayState.upcoming => const StatusPill(
          label: 'Upcoming',
          color: VouchColors.mist,
          icon: Icons.hourglass_empty_rounded,
        ),
    };
  }

  factory StatusPill.mark(DayStatus status, {bool dense = false}) =>
      StatusPill.day(
        switch (status) {
          DayStatus.completed => VouchDayState.completed,
          DayStatus.missed => VouchDayState.missed,
          DayStatus.pending => VouchDayState.pending,
        },
        dense: dense,
      );

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.14);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 9 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 13 : 15, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 11.5 : 12.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
