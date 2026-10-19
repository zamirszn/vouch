/// Small rounded status label used for days, tracks and roles.
library;

import 'package:flutter/material.dart';

import '../core/date_utils.dart';
import '../models/day_entry.dart';
import 'poster.dart';

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

  factory StatusPill.day(VouchDayState state, {bool dense = false}) {
    return switch (state) {
      VouchDayState.completed => StatusPill(
        label: 'Kept',
        color: PosterColors.kelly,
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
        color: PosterColors.cobalt,
        icon: Icons.schedule_rounded,
      ),
      VouchDayState.rest => const StatusPill(
        label: 'Rest',
        color: Color(0xFF8A857C),
        icon: Icons.bedtime_outlined,
      ),
      VouchDayState.upcoming => const StatusPill(
        label: 'Upcoming',
        color: Color(0xFF8A857C),
        icon: Icons.hourglass_empty_rounded,
      ),
    };
  }

  factory StatusPill.mark(DayStatus status, {bool dense = false}) =>
      StatusPill.day(switch (status) {
        DayStatus.completed => VouchDayState.completed,
        DayStatus.missed => VouchDayState.missed,
        DayStatus.pending => VouchDayState.pending,
      }, dense: dense);

  @override
  Widget build(BuildContext context) {
    final bg = color.withValues(alpha: 0.12);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: dense ? 9.5 : 10.5,
              letterSpacing: 1,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
