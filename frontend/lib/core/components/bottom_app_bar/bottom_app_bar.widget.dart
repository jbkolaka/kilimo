import 'package:flutter/material.dart';
import 'package:mwandu/core/theme/variables.dart' hide Theme, Radius;

import 'bottom_app_bar.props.dart';
import 'bottom_app_bar.styles.dart';

typedef _Styles = CBottomAppBarStyles;

/// Carbon Bottom App Bar component for mobile navigation.
///
/// Implements Carbon Design System tokens, interactive states, top divider,
/// and signature active top accent indicator for primary mobile tabs.
class CBottomAppBar extends StatelessWidget {
  const CBottomAppBar({
    super.key,
    required this.items,
    this.currentIndex = 0,
    this.onTap,
    this.showLabels = true,
    this.height = _Styles.defaultHeight,
    this.elevation = 0.0,
    this.showActiveTopIndicator = true,
    this.backgroundColor,
  });

  /// Factory constructor using a props object.
  CBottomAppBar.fromProps({
    super.key,
    required CBottomAppBarProps props,
    this.backgroundColor,
  }) : items = props.items,
       currentIndex = props.currentIndex,
       onTap = props.onTap,
       showLabels = props.showLabels,
       height = props.height,
       elevation = props.elevation,
       showActiveTopIndicator = props.showActiveTopIndicator;

  final List<CBottomAppBarItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final bool showLabels;
  final double height;
  final double elevation;
  final bool showActiveTopIndicator;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final resolvedBg = backgroundColor ?? _Styles.backgroundColor(tokens);
    final borderColor = _Styles.topBorderColor(tokens);

    return Container(
      decoration: BoxDecoration(
        color: resolvedBg,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: tokens.overlay.withValues(alpha: 0.12),
                  offset: const Offset(0, -2),
                  blurRadius: elevation * 2,
                ),
              ]
            : null,
        border: Border(
          top: BorderSide(
            color: borderColor,
            width: _Styles.topBorderThickness,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < items.length; i++)
                Expanded(
                  child: _CBottomAppBarItemWidget(
                    item: items[i],
                    index: i,
                    isSelected: i == currentIndex,
                    showLabels: showLabels,
                    showActiveTopIndicator: showActiveTopIndicator,
                    onTap: () => onTap?.call(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CBottomAppBarItemWidget extends StatelessWidget {
  const _CBottomAppBarItemWidget({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.showLabels,
    required this.showActiveTopIndicator,
    required this.onTap,
  });

  final CBottomAppBarItem item;
  final int index;
  final bool isSelected;
  final bool showLabels;
  final bool showActiveTopIndicator;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isEnabled = item.enabled;

    final iconColor = _Styles.iconColor(
      tokens: tokens,
      isSelected: isSelected,
      isEnabled: isEnabled,
    );
    final labelColor = _Styles.labelColor(
      tokens: tokens,
      isSelected: isSelected,
      isEnabled: isEnabled,
    );
    final indicatorColor = _Styles.activeIndicatorColor(tokens);

    final Widget iconWidget = IconTheme(
      data: IconThemeData(color: iconColor, size: _Styles.iconSize),
      child: isSelected && item.selectedIcon != null
          ? item.selectedIcon!
          : item.icon,
    );

    final Widget content = Stack(
      alignment: Alignment.center,
      children: [
        // Top active indicator line
        if (showActiveTopIndicator)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: _Styles.activeIndicatorHeight,
              color: isSelected ? indicatorColor : Colors.transparent,
            ),
          ),

        // Main icon + label column
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with badge support
              Stack(
                clipBehavior: Clip.none,
                children: [
                  iconWidget,
                  if (item.badgeCount != null || item.badgeLabel != null)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.supportError,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          item.badgeCount != null
                              ? (item.badgeCount! > 99
                                    ? '99+'
                                    : item.badgeCount.toString())
                              : (item.badgeLabel ?? ''),
                          style: TextStyle(
                            color: tokens.textOnColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              if (showLabels) ...[
                const SizedBox(height: Spacing.v4px025remSpacing02),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: _Styles.labelFontSize,
                    fontWeight: _Styles.labelFontWeight(isSelected),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        hoverColor: _Styles.hoverColor(tokens),
        highlightColor: _Styles.activeColor(tokens),
        splashColor: Colors.transparent,
        child: Semantics(
          selected: isSelected,
          label: item.tooltip ?? item.label,
          button: true,
          enabled: isEnabled,
          child: content,
        ),
      ),
    );
  }
}
