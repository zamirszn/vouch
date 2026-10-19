/// The app's page frame: atmosphere, scope and optional bottom chrome.
library;

import 'package:flutter/widgets.dart';

import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import 'gradient_field.dart';

class VouchScaffold extends StatelessWidget {
  const VouchScaffold({
    super.key,
    required this.tone,
    required this.body,
    this.bottomBar,
    this.animateBackground = true,
    this.background,
  });

  final VouchTone tone;
  final Widget body;
  final Widget? bottomBar;
  final bool animateBackground;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return VouchScope(
      theme: theme,
      tone: tone,
      child: ColoredBox(
        color: background ?? theme.canvas,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            GradientField(tone: tone, animate: animateBackground),
            body,
            if (bottomBar != null)
              Positioned(left: 0, right: 0, bottom: 0, child: bottomBar!),
          ],
        ),
      ),
    );
  }
}
