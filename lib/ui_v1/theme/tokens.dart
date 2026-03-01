// Design tokens v1.0: colors, typography, spacing, radius, shadows, motion.
// Light and dark sets (dark is not an inversion of light).

import 'package:flutter/material.dart';

// --- Colors ---

/// Color token set for one theme (light or dark).
class UiV1ColorTokens {
  const UiV1ColorTokens({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentSubtle,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.neutral,
    required this.hoverBg,
    required this.selectedBg,
    required this.focusRing,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentSubtle;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color neutral;
  final Color hoverBg;
  final Color selectedBg;
  final Color focusRing;

  /// Light theme colors (DesignTokens §5).
  static const UiV1ColorTokens light = UiV1ColorTokens(
    bg: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2F4F7),
    border: Color(0xFFE3E7EE),
    divider: Color(0xFFEDF0F5),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF6B7280),
    accent: Color(0xFF2563EB),
    accentSubtle: Color(0xFFEFF6FF),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
    neutral: Color(0xFF6B7280),
    hoverBg: Color(0x0A111827),
    selectedBg: Color(0x142563EB),
    focusRing: Color(0xFF2563EB),
  );

  /// Dark theme colors (DesignTokens §6, not inversion).
  static const UiV1ColorTokens dark = UiV1ColorTokens(
    bg: Color(0xFF0B1220),
    surface: Color(0xFF0F1A2B),
    surfaceAlt: Color(0xFF111F33),
    border: Color(0xFF22324A),
    divider: Color(0xFF1B2A40),
    textPrimary: Color(0xFFE5E7EB),
    textSecondary: Color(0xFFAAB3C2),
    textMuted: Color(0xFF8892A6),
    accent: Color(0xFF4F8BFF),
    accentSubtle: Color(0x1A4F8BFF),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF4F8BFF),
    neutral: Color(0xFF8892A6),
    hoverBg: Color(0x14FFFFFF),
    selectedBg: Color(0x1A4F8BFF),
    focusRing: Color(0xFF4F8BFF),
  );
}

// --- Typography (DesignTokens §1) ---

/// Typography tokens: font family, sizes (xs–2xl), line heights, weights.
class UiV1TypographyTokens {
  const UiV1TypographyTokens({
    required this.fontFamily,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.lineHeightXs,
    required this.lineHeightSm,
    required this.lineHeightMd,
    required this.lineHeightLg,
    required this.lineHeightXl,
    required this.lineHeightXxl,
    required this.regular,
    required this.medium,
    required this.semibold,
  });

  final String fontFamily;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double lineHeightXs;
  final double lineHeightSm;
  final double lineHeightMd;
  final double lineHeightLg;
  final double lineHeightXl;
  final double lineHeightXxl;
  final FontWeight regular;
  final FontWeight medium;
  final FontWeight semibold;

  /// Desktop typography: xs 12/16, sm 13/18, md 14/20, lg 16/22, xl 20/28, 2xl 24/32.
  static const UiV1TypographyTokens standard = UiV1TypographyTokens(
    fontFamily: 'Inter',
    xs: 12,
    sm: 13,
    md: 14,
    lg: 16,
    xl: 20,
    xxl: 24,
    lineHeightXs: 16,
    lineHeightSm: 18,
    lineHeightMd: 20,
    lineHeightLg: 22,
    lineHeightXl: 28,
    lineHeightXxl: 32,
    regular: FontWeight.w400,
    medium: FontWeight.w500,
    semibold: FontWeight.w600,
  );
}

// --- Spacing 8px grid (DesignTokens §2) ---

/// Spacing scale: 0, 4, 8, 12, 16, 20, 24, 32, 40, 48.
class UiV1SpacingTokens {
  const UiV1SpacingTokens({
    required this.none,
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.xxxl,
    required this.xxxxl,
  });

  final double none;
  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double xxxl;
  final double xxxxl;

  static const UiV1SpacingTokens standard = UiV1SpacingTokens(
    none: 0,
    xxs: 4,
    xs: 8,
    sm: 12,
    md: 16,
    lg: 20,
    xl: 24,
    xxl: 32,
    xxxl: 40,
    xxxxl: 48,
  );
}

// --- Radius (DesignTokens §3) ---

/// Radius tokens: xs 4, sm 6, md 8, lg 12.
class UiV1RadiusTokens {
  const UiV1RadiusTokens({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;

  static const UiV1RadiusTokens standard = UiV1RadiusTokens(
    xs: 4,
    sm: 6,
    md: 8,
    lg: 12,
  );
}

// --- Shadows / elevation (DesignTokens §4) ---

/// Shadow levels: 0 none, 1 subtle, 2 medium. Dark theme prefers borders.
class UiV1ShadowTokens {
  const UiV1ShadowTokens({
    required this.level0,
    required this.level1,
    required this.level2,
  });

  final List<BoxShadow> level0;
  final List<BoxShadow> level1;
  final List<BoxShadow> level2;

  static const UiV1ShadowTokens light = UiV1ShadowTokens(
    level0: [],
    level1: [
      BoxShadow(
        color: Color(0x0D000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
    ],
    level2: [
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 2),
        blurRadius: 6,
        spreadRadius: 0,
      ),
    ],
  );

  static const UiV1ShadowTokens dark = UiV1ShadowTokens(
    level0: [],
    level1: [
      BoxShadow(
        color: Color(0x1A000000),
        offset: Offset(0, 1),
        blurRadius: 2,
        spreadRadius: 0,
      ),
    ],
    level2: [
      BoxShadow(
        color: Color(0x26000000),
        offset: Offset(0, 2),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  );
}

// --- Motion (DesignTokens §9) ---

/// Durations: fast 120ms, normal 180ms, slow 240ms.
class UiV1MotionTokens {
  const UiV1MotionTokens({
    required this.fast,
    required this.normal,
    required this.slow,
  });

  final Duration fast;
  final Duration normal;
  final Duration slow;

  static const UiV1MotionTokens standard = UiV1MotionTokens(
    fast: Duration(milliseconds: 120),
    normal: Duration(milliseconds: 180),
    slow: Duration(milliseconds: 240),
  );
}

// --- Combined tokens (light / dark) ---

/// Full token set for one brightness. Dark has its own color/shadow set.
class UiV1Tokens {
  const UiV1Tokens({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radius,
    required this.shadows,
    required this.motion,
  });

  final UiV1ColorTokens colors;
  final UiV1TypographyTokens typography;
  final UiV1SpacingTokens spacing;
  final UiV1RadiusTokens radius;
  final UiV1ShadowTokens shadows;
  final UiV1MotionTokens motion;

  static const UiV1Tokens light = UiV1Tokens(
    colors: UiV1ColorTokens.light,
    typography: UiV1TypographyTokens.standard,
    spacing: UiV1SpacingTokens.standard,
    radius: UiV1RadiusTokens.standard,
    shadows: UiV1ShadowTokens.light,
    motion: UiV1MotionTokens.standard,
  );

  static const UiV1Tokens dark = UiV1Tokens(
    colors: UiV1ColorTokens.dark,
    typography: UiV1TypographyTokens.standard,
    spacing: UiV1SpacingTokens.standard,
    radius: UiV1RadiusTokens.standard,
    shadows: UiV1ShadowTokens.dark,
    motion: UiV1MotionTokens.standard,
  );
}
