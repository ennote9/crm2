// Theme entry point for ui_v1. Public API: getTheme(mode, density).

import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'density.dart';
import 'light_theme.dart';
import 'tokens.dart';

export 'density.dart';
export 'dark_theme.dart';
export 'light_theme.dart';
export 'tokens.dart';

/// Returns the ui_v1 theme for the given [mode] and [density].
/// Optional [tokens] override the default light/dark token set.
ThemeData getTheme(
  Brightness mode,
  UiV1Density density, {
  UiV1Tokens? tokens,
}) {
  switch (mode) {
    case Brightness.light:
      return uiV1LightTheme(tokens: tokens, density: density);
    case Brightness.dark:
      return uiV1DarkTheme(tokens: tokens, density: density);
  }
}
