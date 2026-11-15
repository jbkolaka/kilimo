import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwandu/core/theme/variables.dart';
import 'package:mwandu/feature/authentication/bloc/auth_bloc.dart';
import 'package:mwandu/feature/notification/model/notification_model.dart';
import 'package:mwandu/feature/notification/service/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Duration _refreshInterval = Duration(seconds: 60);

  final NotificationService _service = NotificationService();
  List<FarmNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  String _selectedFilter = 'All'; // 'All', 'Critical', 'Satellite', 'Soil'

  @override
  void initState() {
    super.initState();
    _fetchLiveAlerts();
    // Keep the feed and unread badge live while the app is open.
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => _fetchLiveAlerts(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveAlerts({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign in to load alerts for your farm location.';
        });
      }
      return;
    }

    final location = authState.user.location;
    if (location.latitude == 0 && location.longitude == 0) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Set your farm location to load local alerts.';
        });
      }
      return;
    }

    try {
      final items = await _service.fetchLiveNotifications(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // A silent background refresh keeps the last good feed on screen.
          if (_notifications.isEmpty) {
            _errorMessage =
                'Could not sync live satellite alerts. Tap to retry.';
          }
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    await _service.markAllRead(_notifications);
    if (!mounted) {
      return;
    }
    setState(() {
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
    });
  }

  List<FarmNotification> get _filteredNotifications {
    switch (_selectedFilter) {
      case 'Critical':
        return _notifications.where((n) => n.isCritical).toList();
      case 'Satellite':
        return _notifications
            .where(
              (n) =>
                  n.category.toLowerCase() == 'satellite' ||
                  n.source.toUpperCase().contains('NASA'),
            )
            .toList();
      case 'Soil':
        return _notifications
            .where(
              (n) =>
                  n.category.toLowerCase() == 'soil' ||
                  n.category.toLowerCase() == 'carbon',
            )
            .toList();
      case 'All':
      default:
        return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.layer01,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live Satellite & Farm Alerts',
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: tokens.supportSuccess,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Live NASA Space API & Backend Synced',
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: tokens.textSecondary, size: 20),
            tooltip: 'Refresh live satellite telemetry',
            onPressed: () => _fetchLiveAlerts(),
          ),
          IconButton(
            icon: Icon(Icons.done_all, color: tokens.textSecondary, size: 20),
            tooltip: 'Mark all as read',
            onPressed: _notifications.isEmpty
                ? null
                : () => _markAllAsRead(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(tokens),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: tokens.interactive,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: Spacing.v16px1remSpacing05),
                        Text(
                          'Streaming live NASA Earth observations...',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : _errorMessage != null
                ? _buildErrorView(tokens)
                : _filteredNotifications.isEmpty
                ? _buildEmptyView(tokens)
                : RefreshIndicator(
                    color: tokens.interactive,
                    onRefresh: () => _fetchLiveAlerts(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(Spacing.v16px1remSpacing05),
                      itemCount: _filteredNotifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: Spacing.v12px075remSpacing04),
                      itemBuilder: (context, index) {
                        final item = _filteredNotifications[index];
                        return _buildNotificationCard(tokens, item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(AppThemeTokens tokens) {
    final filters = ['All', 'Critical', 'Satellite', 'Soil'];

    return Container(
      color: tokens.layer01,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.v16px1remSpacing05,
        vertical: Spacing.v8px05remSpacing03,
      ),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          int badge = 0;
          if (f == 'Critical') {
            badge = _notifications.where((n) => n.isCritical).length;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = f),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? tokens.interactive
                      : tokens.background.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? tokens.interactive
                        : tokens.borderSubtle01,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f,
                      style: TextStyle(
                        color: isSelected
                            ? tokens.textOnColor
                            : tokens.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (badge > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.supportError,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$badge',
                          style: TextStyle(
                            color: tokens.textOnColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationCard(AppThemeTokens tokens, FarmNotification item) {
    Color borderLeftColor;
    Color iconBgColor;
    Color iconColor;

    switch (item.severity) {
      case NotificationSeverity.critical:
        borderLeftColor = tokens.supportError;
        iconBgColor = tokens.supportError.withValues(alpha: 0.12);
        iconColor = tokens.supportError;
        break;
      case NotificationSeverity.warning:
        borderLeftColor = tokens.supportWarning;
        iconBgColor = tokens.supportWarning.withValues(alpha: 0.12);
        iconColor = tokens.supportWarning;
        break;
      case NotificationSeverity.success:
        borderLeftColor = tokens.supportSuccess;
        iconBgColor = tokens.supportSuccess.withValues(alpha: 0.12);
        iconColor = tokens.supportSuccess;
        break;
      case NotificationSeverity.info:
      default:
        borderLeftColor = tokens.interactive;
        iconBgColor = tokens.backgroundBrand.withValues(alpha: 0.12);
        iconColor = tokens.interactive;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.v16px1remSpacing05),
      decoration: BoxDecoration(
        color: tokens.layer01,
        border: Border(
          left: BorderSide(color: borderLeftColor, width: 4),
          top: BorderSide(color: tokens.borderSubtle01),
          right: BorderSide(color: tokens.borderSubtle01),
          bottom: BorderSide(color: tokens.borderSubtle01),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: iconBgColor,
            child: Icon(item.icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: Spacing.v12px075remSpacing04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      item.timeAgo,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.v4px025remSpacing02),
                Text(
                  item.description,
                  style: TextStyle(
                    color: tokens.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                if (item.metricValue != null &&
                    item.metricValue!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.background,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: tokens.borderSubtle01),
                        ),
                        child: Text(
                          'Telemetry: ${item.metricValue!}',
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.backgroundBrand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.source,
                          style: TextStyle(
                            color: tokens.interactive,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.recommendation != null &&
                    item.recommendation!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: tokens.background.withValues(alpha: 0.5),
                      border: Border(
                        left: BorderSide(
                          color: tokens.borderSubtle01,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Action: ${item.recommendation!}',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(AppThemeTokens tokens) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: tokens.supportSuccess,
          ),
          const SizedBox(height: Spacing.v16px1remSpacing05),
          Text(
            'All Clear in Your Farm Sector',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'NASA satellites report optimal soil and thermal conditions.',
            style: TextStyle(color: tokens.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(AppThemeTokens tokens) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.satellite_alt_outlined,
              size: 44,
              color: tokens.supportWarning,
            ),
            const SizedBox(height: Spacing.v16px1remSpacing05),
            Text(
              _errorMessage ?? 'Unable to connect to NASA satellite feed',
              textAlign: TextAlign.center,
              style: TextStyle(color: tokens.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _fetchLiveAlerts(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Telemetry Sync'),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.interactive,
                foregroundColor: tokens.textOnColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
