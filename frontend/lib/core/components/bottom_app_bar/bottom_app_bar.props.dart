import 'package:flutter/widgets.dart';

/// Item descriptor for a single tab in [CBottomAppBar].
class CBottomAppBarItem {
  const CBottomAppBarItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeCount,
    this.badgeLabel,
    this.tooltip,
    this.enabled = true,
  });

  /// Primary label displayed beneath or beside the icon.
  final String label;

  /// Default icon displayed when unselected.
  final Widget icon;

  /// Optional icon displayed when selected. If null, [icon] is used.
  final Widget? selectedIcon;

  /// Optional numeric count to display in an indicator badge.
  final int? badgeCount;

  /// Optional text label for the badge (takes precedence if [badgeCount] is null).
  final String? badgeLabel;

  /// Optional tooltip message for accessibility.
  final String? tooltip;

  /// Whether this tab item is interactive.
  final bool enabled;
}

/// Configuration properties for [CBottomAppBar].
class CBottomAppBarProps {
  const CBottomAppBarProps({
    required this.items,
    this.currentIndex = 0,
    this.onTap,
    this.showLabels = true,
    this.elevation = 0.0,
    this.height = 64.0,
    this.showActiveTopIndicator = true,
  });

  /// Collection of navigation items.
  final List<CBottomAppBarItem> items;

  /// The index of the currently selected item.
  final int currentIndex;

  /// Callback invoked when a tab is tapped.
  final ValueChanged<int>? onTap;

  /// Whether labels are visible under icons.
  final bool showLabels;

  /// Elevation shadow value (Carbon standard is 0 with a top border).
  final double elevation;

  /// Total height of the bottom app bar (standard is 56-64).
  final double height;

  /// Whether to render Carbon's signature top active accent bar on the selected tab.
  final bool showActiveTopIndicator;
}
