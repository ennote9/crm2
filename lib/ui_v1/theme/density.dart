// Density: dense / comfortable. Heights and paddings per DesignTokens §7.

import 'package:flutter/material.dart';

/// Density mode for ui_v1 layout.
enum UiV1Density {
  dense,
  comfortable,
}

/// Component heights and paddings for the current density.
class UiV1DensityTokens {
  const UiV1DensityTokens({
    required this.buttonHeight,
    required this.buttonHeightLarge,
    required this.inputHeight,
    required this.tableHeaderHeight,
    required this.tableRowHeight,
    required this.tableCellPaddingX,
    required this.tableCellPaddingY,
    required this.chipHeight,
    required this.chipPaddingX,
  });

  final double buttonHeight;
  final double buttonHeightLarge;
  final double inputHeight;
  final double tableHeaderHeight;
  final double tableRowHeight;
  final double tableCellPaddingX;
  final double tableCellPaddingY;
  final double chipHeight;
  final double chipPaddingX;

  /// Dense: button 32, input 32, table header 32, row 36, cell y=6.
  static const UiV1DensityTokens dense = UiV1DensityTokens(
    buttonHeight: 32,
    buttonHeightLarge: 40,
    inputHeight: 32,
    tableHeaderHeight: 32,
    tableRowHeight: 36,
    tableCellPaddingX: 12,
    tableCellPaddingY: 6,
    chipHeight: 22,
    chipPaddingX: 8,
  );

  /// Comfortable (default): button 36, input 36, table header 36, row 44, cell y=10.
  static const UiV1DensityTokens comfortable = UiV1DensityTokens(
    buttonHeight: 36,
    buttonHeightLarge: 40,
    inputHeight: 36,
    tableHeaderHeight: 36,
    tableRowHeight: 44,
    tableCellPaddingX: 12,
    tableCellPaddingY: 10,
    chipHeight: 24,
    chipPaddingX: 10,
  );

  static UiV1DensityTokens forDensity(UiV1Density density) {
    switch (density) {
      case UiV1Density.dense:
        return UiV1DensityTokens.dense;
      case UiV1Density.comfortable:
        return UiV1DensityTokens.comfortable;
    }
  }
}

/// Resolves Flutter [VisualDensity] from ui_v1 density.
VisualDensity uiV1VisualDensity(UiV1Density density) {
  switch (density) {
    case UiV1Density.dense:
      return VisualDensity.compact;
    case UiV1Density.comfortable:
      return VisualDensity.standard;
  }
}
