/// Section titles and expressive surface containers.
library;

import 'package:flutter/material.dart';

import '../theme/vouch_shapes.dart';
import 'pressable_spring.dart';
import 'soul.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.index,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(2, 0, 2, 12),
  });

  final String title;

  /// Optional editorial number, e.g. `01`. Rendered above the title as a
  /// numbered margin note with a dashed rule.
  final String? index;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (index != null) ...<Widget>[
            Row(
              children: <Widget>[
                Text(
                  index!,
                  style: text.labelSmall?.copyWith(
                    color: scheme.secondary,
                    letterSpacing: 1.2,
                    fontVariations: const <FontVariation>[
                      FontVariation('wght', 800),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: DashRule()),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: text.titleLarge),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ],
      ),
    );
  }
}

class ExpressiveCard extends StatelessWidget {
  const ExpressiveCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.radius = VouchShapes.card,
    this.border = true,
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerHigh,
        borderRadius: radius,
        border: border
            ? Border.all(
                color: scheme.onSurface.withValues(
                  alpha: scheme.brightness == Brightness.dark ? 0.10 : 0.08,
                ),
                width: 1.2,
              )
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;
    return PressableSpring(
      onTap: onTap,
      pressedScale: 0.975,
      child: content,
    );
  }
}
