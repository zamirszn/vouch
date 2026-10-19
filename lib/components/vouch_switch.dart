/// Custom switch with a spring thumb.
library;

import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

import '../design/vouch_motion.dart';
import '../design/vouch_theme.dart';
import 'pressable.dart';

class VouchSwitch extends StatelessWidget {
  const VouchSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 50,
    this.height = 30,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final thumb = height - 8;
    final enabled = onChanged != null;
    final trackOn = theme.accent;
    final trackOff = theme.isDark
        ? const Color(0x1FFFFFFF)
        : const Color(0x22000000);

    final base = Container(      width: width,
      height: height,
      decoration: BoxDecoration(
        color: value ? trackOn : trackOff,
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: theme.line, width: 1),
      ),
      child: Stack(
        children: <Widget>[
          SingleMotionBuilder(
            value: value ? 1 : 0,
            motion: VouchMotion.resolve(
              context,
              value ? VouchMotion.release : VouchMotion.exit,
            ),
            builder: (context, progress, child) => Positioned(
              left: 3 + (width - thumb - 6) * progress,
              top: 3,
              child: child!,
            ),
            child: Container(
              width: thumb,
              height: thumb,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value
                    ? const Color(0xFF0B0B0C)
                    : theme.isDark
                        ? const Color(0xFFE9E9E7)
                        : const Color(0xFFFFFFFF),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      toggled: value,
      enabled: enabled,
      label: semanticLabel,
      child: Pressable(
        onTap: enabled ? () => onChanged!(!value) : null,
        haptic: false,
        scale: 0.94,
        child: enabled ? base : Opacity(opacity: 0.45, child: base),
      ),
    );
  }
}

/// A row with a title, description and switch, used by Settings.
class VouchSwitchRow extends StatelessWidget {
  const VouchSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.leading,
  });

  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'InstrumentSans',
                    fontSize: 15,
                    color: theme.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    style: TextStyle(
                      fontFamily: 'InstrumentSans',
                      fontSize: 13,
                      height: 1.35,
                      color: theme.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          VouchSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
