import 'package:flutter/material.dart';

enum NotificationSeverity {
  critical,
  warning,
  info,
  success;

  static NotificationSeverity fromString(String val) {
    switch (val.toLowerCase()) {
      case 'critical':
        return NotificationSeverity.critical;
      case 'warning':
        return NotificationSeverity.warning;
      case 'success':
        return NotificationSeverity.success;
      case 'info':
      default:
        return NotificationSeverity.info;
    }
  }
}

class FarmNotification {
  final String id;
  final String title;
  final String description;
  final String category;
  final NotificationSeverity severity;
  final bool isCritical;
  final String source;
  final String? metricValue;
  final String? recommendation;
  final DateTime timestamp;
  final bool isRead;

  const FarmNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.isCritical,
    required this.source,
    this.metricValue,
    this.recommendation,
    required this.timestamp,
    this.isRead = false,
  });

  factory FarmNotification.fromJson(Map<String, dynamic> json) {
    return FarmNotification(
      // Deterministic fallback keeps read state stable when the server omits an id.
      id: json['id'] as String? ??
          '${json['title'] ?? 'alert'}-${json['timestamp'] ?? ''}',
      title: json['title'] as String? ?? 'NASA Satellite Advisory',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'satellite',
      severity: NotificationSeverity.fromString(
        json['severity'] as String? ?? 'info',
      ),
      isCritical: json['is_critical'] as bool? ?? false,
      source: json['source'] as String? ?? 'NASA Earth Observations',
      metricValue: json['metric_value'] as String?,
      recommendation: json['recommendation'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: false,
    );
  }

  FarmNotification copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    NotificationSeverity? severity,
    bool? isCritical,
    String? source,
    String? metricValue,
    String? recommendation,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return FarmNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      isCritical: isCritical ?? this.isCritical,
      source: source ?? this.source,
      metricValue: metricValue ?? this.metricValue,
      recommendation: recommendation ?? this.recommendation,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  /// Human readable age of the alert, derived from [timestamp] so it stays
  /// accurate as the app runs and refreshes instead of frozen server text.
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${diff.inDays}d ago';
  }

  IconData get icon {
    switch (category.toLowerCase()) {
      case 'satellite':
      case 'irrigation':
        return Icons.water_drop_outlined;
      case 'climate':
        return Icons.thermostat_outlined;
      case 'soil':
        return Icons.science_outlined;
      case 'carbon':
        return Icons.eco_outlined;
      default:
        return Icons.satellite_alt_outlined;
    }
  }
}
