/// Photo-or-initials avatar with an expressive ring.
library;

import 'package:flutter/material.dart';

class VouchAvatar extends StatelessWidget {
  const VouchAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 48,
    this.backgroundColor,
    this.foregroundColor,
    this.ring = false,
  });

  final String name;
  final String? photoUrl;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool ring;

  String get _initials {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? scheme.primaryContainer;
    final fg = foregroundColor ?? scheme.onPrimaryContainer;
    final url = photoUrl;

    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || url.isEmpty
            ? ColoredBox(
                color: bg,
                child: Center(
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: fg,
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: bg,
                  child: Center(
                    child: Text(
                      _initials,
                      style: TextStyle(
                        color: fg,
                        fontSize: size * 0.36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );

    if (!ring) return avatar;

    final dark = scheme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface,
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.8),
          width: 1.4,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: dark ? 0.5 : 0.20),
            offset: const Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: avatar,
    );
  }
}
