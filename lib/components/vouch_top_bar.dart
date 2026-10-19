/// Brand wordmark and the shared top bar used across screens.
library;

import 'package:flutter/widgets.dart';

import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import 'pressable.dart';
import 'vouch_icon.dart';

class VouchWordmark extends StatelessWidget {
  const VouchWordmark({
    super.key,
    this.color,
    this.size = 13,
    this.tracking = 3.4,
  });

  final Color? color;
  final double size;
  final double tracking;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Text(
      'VOUCH',
      style: TextStyle(
        fontFamily: VouchFonts.display,
        fontSize: size,
        letterSpacing: tracking,
        height: 1,
        color: color ?? theme.ink,
        fontVariations: const <FontVariation>[FontVariation('wght', 700)],
      ),
    );
  }
}

class VouchTopBar extends StatelessWidget {
  const VouchTopBar({
    super.key,
    this.leading,
    this.trailing,
    this.annotation,
    this.padding = const EdgeInsets.fromLTRB(
      VouchSpace.gutter,
      VouchSpace.x3,
      VouchSpace.gutter,
      VouchSpace.x4,
    ),
  });

  final Widget? leading;
  final Widget? trailing;
  final String? annotation;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          leading ?? const VouchWordmark(),
          const Spacer(),
          if (annotation != null)
            Padding(
              padding: const EdgeInsets.only(right: VouchSpace.x3),
              child: Text(
                annotation!,
                style: VouchType.label(theme.muted, size: 10),
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Top bar for pages pushed above the shell: back circle plus wordmark.
class VouchBackBar extends StatelessWidget {
  const VouchBackBar({super.key, this.annotation});

  final String? annotation;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return VouchTopBar(
      annotation: annotation,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Pressable(
            haptic: false,
            semanticLabel: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.glassStrong,
                border: Border.all(color: theme.line, width: 1),
              ),
              child: VouchIcon(
                VouchGlyph.chevronLeft,
                size: 15,
                color: theme.ink,
              ),
            ),
          ),
          const SizedBox(width: VouchSpace.x3),
          const VouchWordmark(size: 12, tracking: 3),
        ],
      ),
    );
  }
}

class VouchAvatar extends StatelessWidget {  const VouchAvatar({
    super.key,
    required this.initials,
    this.size = 36,
    this.onTap,
    this.background,
    this.foreground,
  });

  final String initials;
  final double size;
  final VoidCallback? onTap;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: background ?? theme.glassStrong,
          border: Border.all(color: theme.line, width: 1),
        ),
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            fontFamily: VouchFonts.display,
            fontSize: size * 0.32,
            letterSpacing: 0.4,
            color: foreground ?? theme.ink,
            fontVariations: const <FontVariation>[FontVariation('wght', 680)],
          ),
        ),
      ),
    );
  }
}
