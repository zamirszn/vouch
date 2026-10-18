/// Vouch's Material 3 Expressive visual system.
library;

import 'package:expressive_m3/expressive_m3.dart';
import 'package:flutter/material.dart';

import 'vouch_shapes.dart';

class VouchColors {
  const VouchColors._();

  static const Color indigo = Color(0xFF5B4BFF);
  static const Color indigoDeep = Color(0xFF241765);
  static const Color indigoSoft = Color(0xFFE6E1FF);
  static const Color coral = Color(0xFFFF6A55);
  static const Color coralSoft = Color(0xFFFFE2DC);
  static const Color lime = Color(0xFFC9F27A);
  static const Color limeDeep = Color(0xFF4C6B12);
  static const Color cream = Color(0xFFFFF8F2);
  static const Color paper = Color(0xFFF6F2EC);
  static const Color ink = Color(0xFF171520);
  static const Color inkSoft = Color(0xFF2B2738);
  static const Color mist = Color(0xFF8D879E);
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
      fontFamily: 'Manrope',
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
        color: scheme.surfaceContainerHigh,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: VouchShapes.card,
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? VouchColors.cream : scheme.primary,
          foregroundColor: isDark ? VouchColors.ink : scheme.onPrimary,
          minimumSize: const Size(64, 58),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(
            fontFamily: 'Bricolage',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontVariations: const <FontVariation>[
              FontVariation('wght', 600),
            ],
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 58),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 17),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant, width: 1.4),
          textStyle: text.labelLarge?.copyWith(
            fontFamily: 'Bricolage',
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
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.72),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        selectedColor: scheme.primaryContainer,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        labelStyle: text.labelLarge?.copyWith(
          fontFamily: 'Bricolage',
          fontWeight: FontWeight.w600,
          fontVariations: const <FontVariation>[FontVariation('wght', 600)],
          color: scheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: text.labelLarge?.copyWith(
          fontFamily: 'Bricolage',
          fontWeight: FontWeight.w700,
          fontVariations: const <FontVariation>[FontVariation('wght', 700)],
          color: scheme.onPrimaryContainer,
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
      onPrimary: Colors.white,
      primaryContainer: VouchColors.indigoSoft,
      onPrimaryContainer: VouchColors.indigoDeep,
      secondary: VouchColors.coral,
      onSecondary: Colors.white,
      secondaryContainer: VouchColors.coralSoft,
      onSecondaryContainer: Color(0xFF5B160D),
      tertiary: VouchColors.lime,
      onTertiary: Color(0xFF253500),
      tertiaryContainer: Color(0xFFE4F8C0),
      onTertiaryContainer: Color(0xFF334A00),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: VouchColors.cream,
      onSurface: VouchColors.ink,
      onSurfaceVariant: Color(0xFF5E5A6B),
      surfaceDim: Color(0xFFE8E1D9),
      surfaceBright: VouchColors.cream,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFFFFCF8),
      surfaceContainer: Color(0xFFF4ECE4),
      surfaceContainerHigh: Color(0xFFEFE7DF),
      surfaceContainerHighest: Color(0xFFE9E1D9),
      outline: Color(0xFF8B8698),
      outlineVariant: Color(0xFFD8D2C9),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: VouchColors.ink,
      onInverseSurface: VouchColors.cream,
      inversePrimary: Color(0xFFC5BDFF),
      surfaceTint: VouchColors.indigo,
    );
  }

  static ColorScheme _darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFC5BDFF),
      onPrimary: Color(0xFF241765),
      primaryContainer: Color(0xFF3B2A9E),
      onPrimaryContainer: Color(0xFFE6E1FF),
      secondary: Color(0xFFFFB4A6),
      onSecondary: Color(0xFF5B160D),
      secondaryContainer: Color(0xFF7A2A1E),
      onSecondaryContainer: Color(0xFFFFDAD3),
      tertiary: VouchColors.lime,
      onTertiary: Color(0xFF253500),
      tertiaryContainer: Color(0xFF3A4F00),
      onTertiaryContainer: Color(0xFFE4F8C0),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: VouchColors.ink,
      onSurface: Color(0xFFF7F1EA),
      onSurfaceVariant: Color(0xFFCAC4D4),
      surfaceDim: Color(0xFF171520),
      surfaceBright: Color(0xFF3A3547),
      surfaceContainerLowest: Color(0xFF0F0D16),
      surfaceContainerLow: Color(0xFF1D1A27),
      surfaceContainer: Color(0xFF221F2D),
      surfaceContainerHigh: Color(0xFF2C2838),
      surfaceContainerHighest: Color(0xFF373243),
      outline: Color(0xFF958EA0),
      outlineVariant: Color(0xFF484250),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: VouchColors.cream,
      onInverseSurface: VouchColors.ink,
      inversePrimary: VouchColors.indigo,
      surfaceTint: Color(0xFFC5BDFF),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    // Bricolage Grotesque carries the expressive voice — display, headlines,
    // titles and pill labels. Manrope keeps body copy calm and legible. Both
    // are variable fonts, so weight is set on the `wght` axis rather than
    // relying on synthetic bolding.
    TextStyle display(
      double size,
      FontWeight weight, {
      double height = 1.05,
      double tracking = -0.6,
      double optical = 40,
    }) {
      return TextStyle(
        fontFamily: 'Bricolage',
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: tracking,
        fontVariations: <FontVariation>[
          FontVariation('wght', weight.value.toDouble()),
          FontVariation('opsz', optical),
          FontVariation('wdth', 100),
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
        fontFamily: 'Manrope',
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: tracking,
        fontVariations: <FontVariation>[
          FontVariation('wght', weight.value.toDouble()),
        ],
        color: scheme.onSurface,
      );
    }

    return TextTheme(
      displayLarge:
          display(64, FontWeight.w700, height: 1.0, tracking: -2.2, optical: 72),
      displayMedium:
          display(50, FontWeight.w700, height: 1.02, tracking: -1.6, optical: 60),
      displaySmall:
          display(39, FontWeight.w700, height: 1.06, tracking: -1.1, optical: 48),
      headlineLarge:
          display(34, FontWeight.w700, height: 1.1, tracking: -0.7, optical: 36),
      headlineMedium:
          display(28, FontWeight.w700, height: 1.12, tracking: -0.5, optical: 32),
      headlineSmall:
          display(24, FontWeight.w700, height: 1.16, tracking: -0.3, optical: 28),
      titleLarge: display(21, FontWeight.w600, height: 1.2, tracking: -0.2,
          optical: 24),
      titleMedium: display(17, FontWeight.w600, height: 1.25, optical: 20),
      titleSmall: display(15, FontWeight.w600, height: 1.3, optical: 18),
      bodyLarge: body(17, FontWeight.w400, height: 1.48),
      bodyMedium: body(15, FontWeight.w400, height: 1.46),
      bodySmall: body(13, FontWeight.w500, height: 1.4),
      labelLarge: body(15, FontWeight.w700, height: 1.2, tracking: 0.1),
      labelMedium: body(13, FontWeight.w700, height: 1.2, tracking: 0.2),
      labelSmall: body(11, FontWeight.w700, height: 1.2, tracking: 0.3),
    );
  }
}
