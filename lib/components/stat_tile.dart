/// Small glass stat tiles and state pills.
library;

import 'package:flutter/widgets.dart';

import '../core/date_utils.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import 'glass_card.dart';

Color toneColor(BuildContext context, VouchTone tone) {
  final theme = VouchScope.of(context);
  return switch (tone) {
    VouchTone.pending => theme.pending,
    VouchTone.kept => theme.kept,
    VouchTone.missed => theme.missed,
    VouchTone.rest => theme.muted,
  };
}

VouchTone toneForDay(VouchDayState state) => switch (state) {
      VouchDayState.completed => VouchTone.kept,
      VouchDayState.missed => VouchTone.missed,
      VouchDayState.pending => VouchTone.pending,
      VouchDayState.rest => VouchTone.rest,
      VouchDayState.upcoming => VouchTone.rest,
    };

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.tone,
  });

  final String label;
  final VouchTone tone;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(VouchRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  VouchType.label(color, size: 9).copyWith(letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.tone = VouchTone.rest,
    this.height = 104,
    this.trailing,
    this.onTap,
  });

  final String value;
  final String label;
  final VouchTone tone;
  final double height;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final accent = toneColor(context, tone);
    return GlassCard(
      radius: VouchRadius.medium,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      onTap: onTap,
      child: SizedBox(
        height: height - 30,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VouchType.label(theme.muted, size: 9),
                  ),
                ),
                ?trailing,
              ],
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VouchType.numeral(theme.ink, size: 34).copyWith(
                height: 1,
                letterSpacing: -1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
