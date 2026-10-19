/// Shared bottom-sheet chrome, printed like a small poster sheet.
library;

import 'package:flutter/material.dart';

import 'poster.dart';

Future<T?> showVouchSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: child,
      );
    },
  );
}

class SheetFrame extends StatelessWidget {
  const SheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: style.ink.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'InstrumentSans',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 0.98,
                        letterSpacing: -1.2,
                        color: style.ink,
                        fontVariations: const <FontVariation>[
                          FontVariation('wght', 700),
                          FontVariation('wdth', 94),
                        ],
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 7),
                      Text(
                        subtitle!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'InstrumentSans',
                          fontSize: 12.5,
                          height: 1.4,
                          color: style.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
          if (actions != null && actions!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 22),
            Divider(height: 1, color: style.line),
            const SizedBox(height: 14),
            for (final action in actions!) ...[
              action,
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class SheetNote extends StatelessWidget {
  const SheetNote({super.key, required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final style = PosterStyle.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: style.soft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: style.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'InstrumentSans',
                fontSize: 11.5,
                height: 1.45,
                color: style.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
