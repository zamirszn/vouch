/// The hero gauge on Home: a wavy ring around an expressive cookie.
library;

import 'package:expressive_m3/expressive_m3.dart';
import 'package:flutter/material.dart';

import '../core/date_utils.dart';
import '../theme/vouch_theme.dart';

class PromiseOrb extends StatelessWidget {
  const PromiseOrb({
    super.key,
    required this.state,
    required this.streak,
    required this.completion,
    required this.caption,
    this.size = 250,
  });

  final VouchDayState state;
  final int streak;
  final double completion;
  final String caption;
  final double size;

  Color get _accent => switch (state) {
        VouchDayState.completed => const Color(0xFF5F9E1F),
        VouchDayState.missed => VouchColors.coral,
        VouchDayState.pending => VouchColors.indigo,
        VouchDayState.rest => VouchColors.mist,
        VouchDayState.upcoming => VouchColors.mist,
      };

  List<Color> get _gradient => switch (state) {
        VouchDayState.completed => const <Color>[
            Color(0xFF7FCB32),
            Color(0xFF3E7A12),
          ],
        VouchDayState.missed => const <Color>[
            VouchColors.coral,
            Color(0xFFC13A24),
          ],
        VouchDayState.pending => const <Color>[
            VouchColors.indigo,
            Color(0xFF2A1E7A),
          ],
        VouchDayState.rest || VouchDayState.upcoming => const <Color>[
            Color(0xFF9E98AB),
            Color(0xFF6D6779),
          ],
      };

  IconData get _icon => switch (state) {
        VouchDayState.completed => Icons.check_rounded,
        VouchDayState.missed => Icons.priority_high_rounded,
        VouchDayState.pending => Icons.local_fire_department_rounded,
        VouchDayState.rest => Icons.nightlight_round,
        VouchDayState.upcoming => Icons.hourglass_top_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: CircularWavyProgress(
              value: completion,
              size: size,
              thickness: 11,
              color: _accent,
              trackColor: _accent.withValues(alpha: 0.16),
              label: null,
              animationId: 'promise-orb-$state',
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutCubic,
            width: size * 0.70,
            height: size * 0.70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradient,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: _accent.withValues(alpha: 0.30),
                  blurRadius: 34,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(_icon, color: VouchColors.cream, size: size * 0.10),
                const SizedBox(height: 2),
                Text(
                  '$streak',
                  style: text.displayMedium?.copyWith(
                    color: VouchColors.cream,
                    fontSize: size * 0.18,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'day streak',
                  style: text.labelMedium?.copyWith(
                    color: VouchColors.cream.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Text(caption, style: text.labelMedium),
            ),
          ),
        ],
      ),
    );
  }
}
