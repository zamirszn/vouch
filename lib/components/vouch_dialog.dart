/// Confirmation dialog on a glass panel. No Material `AlertDialog`.
library;

import 'package:flutter/widgets.dart';

import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import 'glass_card.dart';
import 'vouch_button.dart';

Future<bool> showVouchConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  String cancel = 'Cancel',
  bool destructive = true,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: const Color(0xB3000000),
    transitionDuration: VouchDurations.base,
    pageBuilder: (context, animation, secondaryAnimation) => VouchDialog(
      title: title,
      message: message,
      action: action,
      cancel: cancel,
      destructive: destructive,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
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
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
  return result ?? false;
}

class VouchDialog extends StatelessWidget {
  const VouchDialog({
    super.key,
    required this.title,
    required this.message,
    required this.action,
    required this.cancel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String action;
  final String cancel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VouchSpace.gutter),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassCard(
            radius: VouchRadius.large,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            background: theme.isDark ? const Color(0xFF15161C) : theme.raised,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: VouchType.title(theme.ink).copyWith(fontSize: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: VouchType.body(theme.muted)
                      .copyWith(fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: VouchSpace.x6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: VouchButton(
                        label: cancel,
                        style: VouchButtonStyle.ghost,
                        height: 46,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: VouchSpace.x3),
                    Expanded(
                      child: VouchButton(
                        label: action,
                        style: destructive
                            ? VouchButtonStyle.danger
                            : VouchButtonStyle.signal,
                        height: 46,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
