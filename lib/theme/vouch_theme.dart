/// Vouch's Material 3 Expressive visual system.
library;

import 'package:expressive_m3/expressive_m3.dart';
import 'package:flutter/material.dart';

import 'vouch_shapes.dart';

/// A print-shop palette: uncoated paper, dense ink and three clashing
/// accents. Flat surfaces, hairline rules, no soft gradients — the colour
/// does the talking, the grid keeps it honest.
class VouchColors {
  const VouchColors._();

  /// Electric cobalt — the "open / in motion" signal.
  static const Color indigo = Color(0xFF2B33E0);
  static const Color indigoDeep = Color(0xFF151B75);
  static const Color indigoSoft = Color(0xFFDADCFB);

  /// Hot tangerine — missed, late, call attention.
  static const Color coral = Color(0xFFFF5A36);
  static const Color coralSoft = Color(0xFFFFDBD2);

  /// Acid chartreuse — the signature accent.
  static const Color lime = Color(0xFFDFF24B);
  static const Color limeDeep = Color(0xFF45510A);

  /// Kelly green — kept.
  static const Color kept = Color(0xFF2F8F4E);
  static const Color keptDeep = Color(0xFF1E5B31);

  /// Paper stocks.
  static const Color cream = Color(0xFFF7F5EE);
  static const Color paper = Color(0xFFEDEBE4);
  static const Color paperDeep = Color(0xFFE2E0D6);

  /// Ink.
  static const Color ink = Color(0xFF12110D);
  static const Color inkSoft = Color(0xFF26231C);

  /// Warm grey used for secondary type and quiet marks.
  static const Color mist = Color(0xFF8A8578);
}

class VouchTheme {
  const VouchTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = isDark ? _darkScheme() : _lightScheme();
    final text = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      fontFamily: 'InstrumentSans',
      textTheme: text,
      primaryTextTheme: text,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: expressivePageTransitionsTheme,
      extensions: <ThemeExtension<dynamic>>[
        EmphasizedTextTheme.of(text),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? scheme.surfaceContainerHigh : VouchColors.cream,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: scheme.onSurface.withValues(alpha: isDark ? 0.16 : 0.12),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? VouchColors.cream : VouchColors.ink,
          foregroundColor: isDark ? VouchColors.ink : VouchColors.cream,
          minimumSize: const Size(64, 58),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(
            fontFamily: 'InstrumentSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
            fontVariations: const <FontVariation>[
              FontVariation('wght', 600),
            ],
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(64, 58),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 17),
          shape: const StadiumBorder(),
          side: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.22),
            width: 1.2,
          ),
          textStyle: text.labelLarge?.copyWith(
            fontFamily: 'InstrumentSans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontVariations: const <FontVariation>[
              FontVariation('wght', 600),
            ],
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: const CircleBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.55)
            : VouchColors.cream,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.onSurface, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        selectedColor: scheme.tertiary,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        labelStyle: text.labelLarge?.copyWith(
          fontFamily: 'InstrumentSans',
          fontWeight: FontWeight.w600,
          fontVariations: const <FontVariation>[FontVariation('wght', 600)],
          color: scheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: text.labelLarge?.copyWith(
          fontFamily: 'InstrumentSans',
          fontWeight: FontWeight.w700,
          fontVariations: const <FontVariation>[FontVariation('wght', 700)],
          color: scheme.onTertiary,
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        iconColor: scheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle:
            text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: VouchShapes.sheet),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        modalBackgroundColor: scheme.surfaceContainerHigh,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: RoundedRectangleBorder(borderRadius: VouchShapes.sheet),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelMedium?.copyWith(
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            fontVariations: <FontVariation>[
              FontVariation('wght', selected ? 800 : 600),
            ],
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            size: selected ? 26 : 24,
          );
        }),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.tertiary,
        textColor: scheme.onTertiary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest;
        }),
      ),
    );
  }

  static ColorScheme _lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: VouchColors.indigo,
      onPrimary: VouchColors.cream,
      primaryContainer: VouchColors.indigoSoft,
      onPrimaryContainer: VouchColors.indigoDeep,
      secondary: VouchColors.coral,
      onSecondary: VouchColors.cream,
      secondaryContainer: VouchColors.coralSoft,
      onSecondaryContainer: Color(0xFF5B160D),
      tertiary: VouchColors.lime,
      onTertiary: VouchColors.ink,
      tertiaryContainer: Color(0xFFEAF6B4),
      onTertiaryContainer: VouchColors.limeDeep,
      error: Color(0xFFB3261E),
      onError: VouchColors.cream,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: VouchColors.paper,
      onSurface: VouchColors.ink,
      onSurfaceVariant: Color(0xFF6F6A5D),
      surfaceDim: Color(0xFFDEDCD2),
      surfaceBright: Color(0xFFFBF9F3),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: VouchColors.cream,
      surfaceContainer: Color(0xFFF0EEE7),
      surfaceContainerHigh: Color(0xFFEAE8DF),
      surfaceContainerHighest: Color(0xFFE2E0D5),
      outline: VouchColors.mist,
      outlineVariant: Color(0xFFD0CDC1),
      shadow: VouchColors.ink,
      scrim: VouchColors.ink,
      inverseSurface: VouchColors.ink,
      onInverseSurface: VouchColors.cream,
      inversePrimary: Color(0xFFA9ADFF),
      surfaceTint: VouchColors.indigo,
    );
  }

  static ColorScheme _darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFA9ADFF),
      onPrimary: Color(0xFF10143F),
      primaryContainer: VouchColors.indigo,
      onPrimaryContainer: Color(0xFFE6E7FF),
      secondary: Color(0xFFFF8F72),
      onSecondary: Color(0xFF451105),
      secondaryContainer: Color(0xFF9C2C13),
      onSecondaryContainer: Color(0xFFFFDAD3),
      tertiary: VouchColors.lime,
      onTertiary: VouchColors.ink,
      tertiaryContainer: Color(0xFF3E4809),
      onTertiaryContainer: Color(0xFFEAF6B4),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: VouchColors.ink,
      onSurface: Color(0xFFF2EFE5),
      onSurfaceVariant: Color(0xFFB4AE9E),
      surfaceDim: VouchColors.ink,
      surfaceBright: Color(0xFF3A362B),
      surfaceContainerLowest: Color(0xFF0B0A07),
      surfaceContainerLow: Color(0xFF1A1812),
      surfaceContainer: Color(0xFF1F1D16),
      surfaceContainerHigh: Color(0xFF27241C),
      surfaceContainerHighest: Color(0xFF312D23),
      outline: Color(0xFF8B8577),
      outlineVariant: Color(0xFF3D392E),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFF2EFE5),
      onInverseSurface: VouchColors.ink,
      inversePrimary: VouchColors.indigo,
      surfaceTint: Color(0xFFA9ADFF),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    // Instrument Sans carries the editorial voice — a neo-grotesque with a
    // real width axis, so large type can be tightened optically instead of
    // faked with letter-spacing alone. Space Mono marks the technical
    // metadata: eyebrows, indices and status stamps.
    TextStyle display(
      double size,
      FontWeight weight, {
      double height = 1.02,
      double tracking = -0.6,
      double width = 100,
    }) {
      return TextStyle(
        fontFamily: 'InstrumentSans',
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: tracking,
        fontVariations: <FontVariation>[
          FontVariation('wght', weight.value.toDouble()),
          FontVariation('wdth', width),
        ],
        color: scheme.onSurface,
      );
    }

    TextStyle body(
      double size,
      FontWeight weight, {
      double height = 1.45,
      double tracking = 0,
    }) {
      return TextStyle(
        fontFamily: 'InstrumentSans',
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: tracking,
        fontVariations: <FontVariation>[
          FontVariation('wght', weight.value.toDouble()),
          FontVariation('wdth', 100),
        ],
        color: scheme.onSurface,
      );
    }

    TextStyle mono(
      double size,
      FontWeight weight, {
      double height = 1.3,
      double tracking = 0.8,
    }) {
      return TextStyle(
        fontFamily: 'SpaceMono',
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: tracking,
        color: scheme.onSurface,
      );
    }

    return TextTheme(
      displayLarge:
          display(64, FontWeight.w700, height: 0.94, tracking: -2.8, width: 94),
      displayMedium:
          display(50, FontWeight.w700, height: 0.96, tracking: -2.2, width: 95),
      displaySmall:
          display(38, FontWeight.w700, height: 1.0, tracking: -1.5, width: 96),
      headlineLarge:
          display(33, FontWeight.w700, height: 1.04, tracking: -1.0, width: 97),
      headlineMedium:
          display(27, FontWeight.w700, height: 1.08, tracking: -0.7),
      headlineSmall:
          display(23, FontWeight.w600, height: 1.14, tracking: -0.4),
      titleLarge: display(20, FontWeight.w600, height: 1.2, tracking: -0.25),
      titleMedium: display(17, FontWeight.w600, height: 1.25, tracking: -0.1),
      titleSmall: display(15, FontWeight.w600, height: 1.3),
      bodyLarge: body(17, FontWeight.w400, height: 1.45),
      bodyMedium: body(15, FontWeight.w400, height: 1.45),
      bodySmall: body(13, FontWeight.w400, height: 1.4),
      labelLarge: body(15, FontWeight.w600, height: 1.2, tracking: 0.1),
      labelMedium: body(12.5, FontWeight.w600, height: 1.2, tracking: 0.25),
      labelSmall: mono(10.5, FontWeight.w400, tracking: 1.0, height: 1.35),
    );
  }
}
