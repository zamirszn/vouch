/// Bottom panel with a frosted surface, a grab handle and a header.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import 'pressable.dart';
import 'vouch_icon.dart';

class VouchSheet extends StatelessWidget {
  const VouchSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.leading,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final surface =
        theme.isDark ? const Color(0xF20C0D12) : const Color(0xF7F3F3EF);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: MediaQuery.sizeOf(context).height * 0.88,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(VouchRadius.sheet),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius:
                          BorderRadius.circular(VouchRadius.sheet),
                      border: Border.all(color: theme.lineStrong, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: theme.lineStrong,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        if (title != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 12, 14, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                if (leading != null) ...<Widget>[
                                  leading!,
                                  const SizedBox(width: VouchSpace.x3),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        title!,
                                        style: VouchType.cardTitle(theme.ink)
                                            .copyWith(fontSize: 22),
                                      ),
                                      if (subtitle != null) ...<Widget>[
                                        const SizedBox(height: 5),
                                        Text(
                                          subtitle!,
                                          style: VouchType.caption(theme.muted)
                                              .copyWith(height: 1.4),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: VouchSpace.x2),
                                Pressable(
                                  semanticLabel: 'Close',
                                  haptic: false,
                                  onTap: () =>
                                      Navigator.of(context).maybePop(),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.glassStrong,
                                      border: Border.all(
                                        color: theme.line,
                                        width: 1,
                                      ),
                                    ),
                                    child: VouchIcon(
                                      VouchGlyph.close,
                                      size: 15,
                                      color: theme.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Flexible(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              22,
                              title == null ? 18 : 20,
                              22,
                              22,
                            ),
                            child: child,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a [VouchSheet] with a barrier, without Material's bottom sheet.
Future<T?> showVouchPanel<T>(
  BuildContext context,
  WidgetBuilder builder,
) {
  return Navigator.of(context).push<T>(
    _VouchPanelRoute<T>(builder: builder),
  );
}

class _VouchPanelRoute<T> extends PageRouteBuilder<T> {
  _VouchPanelRoute({required WidgetBuilder builder})
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: const Color(0xB3000000),
          barrierLabel: 'Dismiss',
          transitionDuration: VouchDurations.base,
          reverseTransitionDuration: VouchDurations.fast,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
              return child;
            }
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
