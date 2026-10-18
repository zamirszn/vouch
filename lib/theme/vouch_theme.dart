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
      fontFamily: 'RobotoFlex',
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
        shape: RoundedRectangleBorder(borderRadius: VouchShapes.card),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant, width: 1.4),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
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
        backgroundColor: scheme.surfaceContainerHighest,
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        height: 76,
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            size: 26,
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
    TextStyle style(
      double size,
      FontWeight weight, {
      double height = 1.15,
      double tracking = 0,
    }) {
      return TextStyle(
        fontFamily: 'RobotoFlex',
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: tracking,
        color: scheme.onSurface,
      );
    }

    return TextTheme(
      displayLarge: style(62, FontWeight.w600, height: 1.02, tracking: -1.8),
      displayMedium: style(48, FontWeight.w600, height: 1.04, tracking: -1.2),
      displaySmall: style(38, FontWeight.w600, height: 1.08, tracking: -0.8),
      headlineLarge: style(34, FontWeight.w700, height: 1.1, tracking: -0.5),
      headlineMedium: style(29, FontWeight.w700, height: 1.12, tracking: -0.3),
      headlineSmall: style(25, FontWeight.w700, height: 1.16),
      titleLarge: style(22, FontWeight.w700, height: 1.2),
      titleMedium: style(17, FontWeight.w700, height: 1.25),
      titleSmall: style(15, FontWeight.w700, height: 1.3),
      bodyLarge: style(17, FontWeight.w400, height: 1.42),
      bodyMedium: style(15, FontWeight.w400, height: 1.42),
      bodySmall: style(13, FontWeight.w400, height: 1.38),
      labelLarge: style(15, FontWeight.w700, height: 1.2, tracking: 0.2),
      labelMedium: style(13, FontWeight.w700, height: 1.2, tracking: 0.3),
      labelSmall: style(11, FontWeight.w700, height: 1.2, tracking: 0.4),
    );
  }
}
