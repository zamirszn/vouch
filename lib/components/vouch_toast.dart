/// Overlay toasts. No SnackBar.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:motor/motor.dart';

import '../design/vouch_motion.dart';
import '../design/vouch_theme.dart';
import '../design/vouch_tokens.dart';
import '../design/vouch_type.dart';
import 'vouch_icon.dart';

class VouchToast {
  VouchToast._();

  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    VouchGlyph glyph = VouchGlyph.checkCircle,
    Color? accent,
    Duration duration = const Duration(milliseconds: 2400),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _entry?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        glyph: glyph,
        accent: accent,
        duration: duration,
        onDone: () {
          entry.remove();
          if (_entry == entry) _entry = null;
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.glyph,
    required this.accent,
    required this.duration,
    required this.onDone,
  });

  final String message;
  final VouchGlyph glyph;
  final Color? accent;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> {
  bool _visible = true;
  Timer? _hide;
  Timer? _remove;

  @override
  void initState() {
    super.initState();
    _hide = Timer(widget.duration, () {
      if (mounted) setState(() => _visible = false);
      _remove = Timer(VouchDurations.base, widget.onDone);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _remove?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = VouchScope.of(context);
    final accent = widget.accent ?? theme.kept;
    final bottom = MediaQuery.maybeOf(context)?.viewPadding.bottom ?? 0;
    return Positioned(
      left: VouchSpace.x5,
      right: VouchSpace.x5,
      bottom: bottom + 96,
      child: IgnorePointer(
        child: SingleMotionBuilder(
          value: _visible ? 1 : 0,
          from: 0,
          motion: VouchMotion.resolve(
            context,
            _visible ? VouchMotion.enterFast : VouchMotion.exit,
          ),
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 18),
              child: child,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.isDark
                  ? const Color(0xF21A1B21)
                  : const Color(0xF2FFFFFF),
              borderRadius: BorderRadius.circular(VouchRadius.medium),
              border: Border.all(color: theme.line),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VouchSpace.x4,
                vertical: 14,
              ),
              child: Row(
                children: <Widget>[
                  VouchIcon(widget.glyph, size: 19, color: accent),
                  const SizedBox(width: VouchSpace.x3),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: VouchType.body(theme.ink)
                          .copyWith(fontSize: 14, height: 1.25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
