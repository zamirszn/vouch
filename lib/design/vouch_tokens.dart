/// Raw design tokens for the Vouch rebuild.
///
/// These are intentionally Material-free: plain colours, gradients, spacing,
/// radii and glows. Widgets read semantic values through `VouchScope`.
library;

import 'dart:ui';

/// The emotional state of today, used to tint the whole screen.
enum VouchTone { pending, kept, missed, rest }

abstract final class VouchColors {
  // Dark stage.
  static const Color canvas = Color(0xFF08090B);
  static const Color canvasRaised = Color(0xFF111218);
  static const Color ink = Color(0xFFF6F6F2);
  static const Color muted = Color(0xFFA2A5AE);
  static const Color faint = Color(0xFF63666F);
  static const Color line = Color(0x1FFFFFFF);
  static const Color lineStrong = Color(0x3DFFFFFF);

  // Signal colours.
  static const Color yellow = Color(0xFFE8FF3A);
  static const Color mint = Color(0xFF67F5B5);
  static const Color mintDeep = Color(0xFF0B5E43);
  static const Color coral = Color(0xFFFF5C5C);
  static const Color violet = Color(0xFF8C7BFF);
  static const Color blue = Color(0xFF4CA6FF);

  // Presentation-board light mode.
  static const Color paper = Color(0xFFE9E9E7);
  static const Color paperRaised = Color(0xFFF4F4F1);
  static const Color paperInk = Color(0xFF0B0B0C);
  static const Color paperMuted = Color(0xFF6D6D70);
  static const Color paperLine = Color(0x1F000000);
}

abstract final class VouchSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x14 = 56;
  static const double x18 = 72;

  static const double gutter = 22;
  static const double minTap = 48;
  static const double navHeight = 68;
}

abstract final class VouchRadius {
  static const double small = 14;
  static const double medium = 20;
  static const double card = 28;
  static const double large = 34;
  static const double sheet = 36;
  static const double pill = 999;
}

abstract final class VouchDurations {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 600);
}

/// Full-screen atmosphere per state. These are observed from the reference
/// shots: one base, one lifted glow, one deep vignette.
abstract final class VouchGradients {
  static const List<Color> pending = <Color>[
    Color(0xFF221551),
    Color(0xFF0C0A18),
    Color(0xFF07070B),
  ];
  static const List<Color> kept = <Color>[
    Color(0xFF0B4B36),
    Color(0xFF081713),
    Color(0xFF07090A),
  ];
  static const List<Color> missed = <Color>[
    Color(0xFF5A0D22),
    Color(0xFF1A070D),
    Color(0xFF0A0608),
  ];
  static const List<Color> rest = <Color>[
    Color(0xFF252830),
    Color(0xFF101116),
    Color(0xFF08090B),
  ];
  static const List<Color> light = <Color>[
    Color(0xFFF2F2EE),
    Color(0xFFE9E9E7),
    Color(0xFFDCDCD7),
  ];

  static List<Color> forTone(VouchTone tone, {bool dark = true}) {
    if (!dark) return light;
    return switch (tone) {
      VouchTone.pending => pending,
      VouchTone.kept => kept,
      VouchTone.missed => missed,
      VouchTone.rest => rest,
    };
  }

  static Color glowFor(VouchTone tone, {bool dark = true}) {
    if (!dark) {
      return switch (tone) {
        VouchTone.pending => const Color(0xFFB7A8FF),
        VouchTone.kept => const Color(0xFF8FF0C8),
        VouchTone.missed => const Color(0xFFFFB1B1),
        VouchTone.rest => const Color(0xFFC9CBD1),
      };
    }
    return switch (tone) {
      VouchTone.pending => VouchColors.violet,
      VouchTone.kept => VouchColors.mint,
      VouchTone.missed => VouchColors.coral,
      VouchTone.rest => VouchColors.muted,
    };
  }
}
