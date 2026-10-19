/// Custom routes. No Material page transitions anywhere in the app.
library;

import 'package:flutter/widgets.dart';

import 'vouch_tokens.dart';

class VouchPageRoute<T> extends PageRouteBuilder<T> {
  VouchPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
    this.fromBottom = false,
  }) : super(
          transitionDuration: VouchDurations.slow,
          reverseTransitionDuration: VouchDurations.base,
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
            final begin = fromBottom
                ? const Offset(0, 0.12)
                : const Offset(0, 0.035);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: begin, end: Offset.zero)
                    .animate(curved),
                child: child,
              ),
            );
          },
        );

  final bool fromBottom;
}

PageRoute<T> vouchPageRoute<T>(
  RouteSettings settings,
  WidgetBuilder builder,
) =>
    VouchPageRoute<T>(settings: settings, builder: builder);

Future<T?> pushVouch<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool fromBottom = false,
}) =>
    Navigator.of(context).push<T>(
      VouchPageRoute<T>(builder: builder, fromBottom: fromBottom),
    );

/// A bottom-sheet-style page: slides up, no fade-through.
class VouchSheetRoute<T> extends PageRouteBuilder<T> {
  VouchSheetRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
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

Future<T?> pushVouchSheet<T>(BuildContext context, WidgetBuilder builder) =>
    Navigator.of(context).push<T>(VouchSheetRoute<T>(builder: builder));
