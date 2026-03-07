// Dark theme for ui_v1. ThemeData from tokens, visible focus ring.

import 'package:flutter/material.dart';

import 'tokens.dart';
import 'density.dart';

const double _focusRingWidth = 2;

ThemeData uiV1DarkTheme({
  UiV1Tokens? tokens,
  UiV1Density density = UiV1Density.dense,
}) {
  final t = tokens ?? UiV1Tokens.dark;
  final c = t.colors;
  final typo = t.typography;
  final radius = t.radius;
  final densityTokens = UiV1DensityTokens.forDensity(density);

  final colorScheme = ColorScheme.dark(
    primary: c.accent,
    onPrimary: Colors.black87,
    primaryContainer: c.accentSubtle,
    onPrimaryContainer: c.textPrimary,
    secondary: c.accent,
    onSecondary: Colors.black87,
    surface: c.surface,
    onSurface: c.textPrimary,
    surfaceContainerHigh: c.surfaceAlt,
    surfaceContainerHighest: c.surfaceElevated,
    onSurfaceVariant: c.textSecondary,
    outline: c.border,
    outlineVariant: c.divider,
    error: c.danger,
    onError: Colors.white,
    errorContainer: c.danger.withValues(alpha: 0.2),
    onErrorContainer: c.danger,
  );

  final focusBorder = OutlineInputBorder(
    borderSide: BorderSide(color: c.focusRing, width: _focusRingWidth),
    borderRadius: BorderRadius.circular(radius.sm),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    visualDensity: uiV1VisualDensity(density),
    fontFamily: typo.fontFamily,
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: typo.xxl,
        height: typo.lineHeightXxl / typo.xxl,
        fontWeight: typo.semibold,
        color: c.textPrimary,
      ),
      displayMedium: TextStyle(
        fontSize: typo.xl,
        height: typo.lineHeightXl / typo.xl,
        fontWeight: typo.semibold,
        color: c.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: typo.xl,
        height: typo.lineHeightXl / typo.xl,
        fontWeight: typo.semibold,
        color: c.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: typo.lg,
        height: typo.lineHeightLg / typo.lg,
        fontWeight: typo.semibold,
        color: c.textPrimary,
      ),
      titleSmall: TextStyle(
        fontSize: typo.sm,
        height: typo.lineHeightSm / typo.sm,
        fontWeight: typo.medium,
        color: c.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: typo.md,
        height: typo.lineHeightMd / typo.md,
        fontWeight: typo.regular,
        color: c.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: typo.sm,
        height: typo.lineHeightSm / typo.sm,
        fontWeight: typo.regular,
        color: c.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: typo.xs,
        height: typo.lineHeightXs / typo.xs,
        fontWeight: typo.regular,
        color: c.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: typo.sm,
        height: typo.lineHeightSm / typo.sm,
        fontWeight: typo.medium,
        color: c.textPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: typo.xs,
        height: typo.lineHeightXs / typo.xs,
        fontWeight: typo.medium,
        color: c.textSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: typo.xs,
        height: typo.lineHeightXs / typo.xs,
        fontWeight: typo.regular,
        color: c.textMuted,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceAlt,
      contentPadding: EdgeInsets.symmetric(
        horizontal: t.spacing.sm,
        vertical: (densityTokens.inputHeight - typo.lineHeightSm) / 2,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius.sm)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: c.border),
        borderRadius: BorderRadius.circular(radius.sm),
      ),
      focusedBorder: focusBorder,
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: c.danger),
        borderRadius: BorderRadius.circular(radius.sm),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: c.danger, width: _focusRingWidth),
        borderRadius: BorderRadius.circular(radius.sm),
      ),
      focusColor: c.focusRing,
    ),
    focusColor: c.focusRing,
    hoverColor: c.hoverBg,
    highlightColor: c.selectedBg,
    dividerColor: c.divider,
    scaffoldBackgroundColor: c.bg,
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.lg),
        side: BorderSide(color: c.border),
      ),
    ),
    iconTheme: IconThemeData(
      size: 24,
      color: c.textSecondary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceAlt,
      side: BorderSide(color: c.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.sm),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: t.spacing.sm,
        vertical: (densityTokens.chipHeight - typo.lineHeightXs) / 2,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: Size(densityTokens.buttonHeight, densityTokens.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.sm),
        ),
        visualDensity: VisualDensity.compact,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return c.accent.withValues(alpha: 0.85);
        return Colors.transparent;
      }),
      side: BorderSide(color: c.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.xs),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(0, densityTokens.buttonHeight),
        padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.sm),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, densityTokens.buttonHeight),
        padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.sm),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: Size(0, densityTokens.buttonHeight),
        padding: EdgeInsets.symmetric(horizontal: t.spacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.sm),
        ),
      ),
    ),
  );
}
