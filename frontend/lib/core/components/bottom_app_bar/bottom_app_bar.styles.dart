import 'package:flutter/widgets.dart';
import 'package:mwandu/core/theme/variables.dart' hide Theme, Radius;

/// Style definitions and token resolvers for Carbon Bottom App Bar.
abstract final class CBottomAppBarStyles {
  /// Default height of the bottom app bar for comfortable mobile touch targets.
  static const double defaultHeight = 64.0;

  /// Compact height variation.
  static const double compactHeight = 56.0;

  /// Thickness of Carbon's top border divider.
  static const double topBorderThickness = 1.0;

  /// Height of the active indicator bar at the top of the selected tab.
  static const double activeIndicatorHeight = 3.0;

  /// Size of tab icons.
  static const double iconSize = 20.0;

  /// Label font size.
  static const double labelFontSize = 11.0;

  /// Resolves the bar background color from Carbon tokens.
  static Color backgroundColor(AppThemeTokens tokens) => tokens.layer01;

  /// Resolves the bar top border color.
  static Color topBorderColor(AppThemeTokens tokens) => tokens.borderSubtle01;

  /// Resolves the active top indicator bar color.
  static Color activeIndicatorColor(AppThemeTokens tokens) =>
      tokens.interactive;

  /// Resolves the icon color depending on active/disabled status.
  static Color iconColor({
    required AppThemeTokens tokens,
    required bool isSelected,
    required bool isEnabled,
  }) {
    if (!isEnabled) return tokens.textDisabled;
    return isSelected ? tokens.interactive : tokens.iconSecondary;
  }

  /// Resolves label color depending on active/disabled status.
  static Color labelColor({
    required AppThemeTokens tokens,
    required bool isSelected,
    required bool isEnabled,
  }) {
    if (!isEnabled) return tokens.textDisabled;
    return isSelected ? tokens.textPrimary : tokens.textSecondary;
  }

  /// Resolves label font weight based on selection state.
  static FontWeight labelFontWeight(bool isSelected) =>
      isSelected ? FontWeight.w600 : FontWeight.w400;

  /// Resolves tab item hover/highlight color.
  static Color hoverColor(AppThemeTokens tokens) => tokens.layerHover01;

  /// Resolves tab item active/pressed color.
  static Color activeColor(AppThemeTokens tokens) => tokens.layerActive01;
}
