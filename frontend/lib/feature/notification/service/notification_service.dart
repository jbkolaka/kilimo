import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mwandu/feature/notification/model/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final Dio _dio;
  final String backendBaseUrl;

  static const String defaultBackendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://kilimo-api-j6ve.onrender.com/api/v1',
  );

  /// SharedPreferences key holding ids of alerts the farmer has already read.
  static const String _readIdsKey = 'notification_read_ids';
  static const int _maxStoredReadIds = 200;

  /// Reactive notifier for unread notification count so bottom nav bar updates live.
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> criticalCountNotifier = ValueNotifier<int>(0);

  NotificationService({Dio? dio, String? backendBaseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          ),
      backendBaseUrl = backendBaseUrl ?? defaultBackendBaseUrl;

  /// Fetches live alerts from the Go backend, falling back directly to live NASA POWER Space API.
  Future<List<FarmNotification>> fetchLiveNotifications({
    required double latitude,
    required double longitude,
  }) async {
    final lat = double.parse(latitude.toStringAsFixed(4));
    final lon = double.parse(longitude.toStringAsFixed(4));

    // Request alerts using only the farm coordinates, not the saved county.
    try {
      final response = await _dio.post(
        '$backendBaseUrl/nasa/notifications',
        data: {'latitude': lat, 'longitude': lon},
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final rawList = data['notifications'] as List<dynamic>? ?? [];
        final list = rawList
            .map((e) => FarmNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        return await _applyReadState(list);
      }
    } catch (e) {
      debugPrint('Backend NASA notification endpoint fallback: $e');
    }

    // Resilient fallback: query NASA POWER directly at the farm coordinates.
    final direct = await _fetchDirectNasaSpaceAlerts(
      lat: lat,
      lon: lon,
      region: 'your farm',
    );
    return _applyReadState(direct);
  }

  /// Queries the live NASA POWER agroclimatology endpoint for the most recent
  /// complete observation window and builds alerts purely from the returned
  /// telemetry. Throws when no real data is available rather than inventing
  /// placeholder values.
  Future<List<FarmNotification>> _fetchDirectNasaSpaceAlerts({
    required double lat,
    required double lon,
    required String region,
  }) async {
    final now = DateTime.now();
    // NASA POWER daily products publish with a lag of a few days.
    final end = now.subtract(const Duration(days: 3));
    final start = end.subtract(const Duration(days: 6));
    final startParam = _formatNasaDate(start);
    final endParam = _formatNasaDate(end);

    final url =
        'https://power.larc.nasa.gov/api/temporal/daily/point?'
        'parameters=GWETTOP,T2M,PRECTOTCORR&community=AG&longitude=$lon&latitude=$lat'
        '&start=$startParam&end=$endParam&format=JSON';

    final Response<dynamic> response;
    try {
      response = await _dio.get(url);
    } catch (e) {
      throw Exception('Live NASA POWER telemetry unavailable: $e');
    }

    final data = response.data;
    Map<String, dynamic>? parameter;
    if (data is Map) {
      final properties = data['properties'];
      if (properties is Map) {
        final params = properties['parameter'];
        if (params is Map) {
          parameter = params.cast<String, dynamic>();
        }
      }
    }
    if (parameter == null) {
      throw Exception('Live NASA POWER telemetry returned no observations');
    }

    final surfaceWetness = _meanValid(parameter['GWETTOP']);
    final avgTemp = _meanValid(parameter['T2M']);
    final dailyPrecip = _meanValid(parameter['PRECTOTCORR']);

    if (surfaceWetness == null && avgTemp == null && dailyPrecip == null) {
      throw Exception(
        'Live NASA POWER telemetry contained no usable values for '
        '$startParam-$endParam',
      );
    }

    final alerts = <FarmNotification>[];
    final windowLabel = '${_shortDate(start)}–${_shortDate(end)}';

    if (surfaceWetness != null) {
      final isMoistureDeficit = surfaceWetness < 0.50;
      alerts.add(
        FarmNotification(
          id: 'smap-${_dayKey(now)}',
          title: isMoistureDeficit
              ? 'NASA Satellite Alert: Soil Moisture Deficit'
              : 'NASA Satellite Update: Adequate Soil Moisture',
          description: isMoistureDeficit
              ? 'Surface wetness (GWETTOP) averaged ${surfaceWetness.toStringAsFixed(2)} in $region over $windowLabel. Supplemental drip irrigation recommended for row crops.'
              : 'Surface soil moisture is favorable at ${surfaceWetness.toStringAsFixed(2)} across the $region agricultural sector ($windowLabel average).',
          category: 'satellite',
          severity: isMoistureDeficit
              ? NotificationSeverity.critical
              : NotificationSeverity.success,
          isCritical: isMoistureDeficit,
          source: 'NASA POWER & SMAP',
          metricValue: '${surfaceWetness.toStringAsFixed(2)} GWETTOP',
          recommendation: isMoistureDeficit
              ? 'Apply supplemental irrigation in early morning or evening to curtail evaporation.'
              : 'Maintain current field schedule; moisture adequate for active nutrient uptake.',
          timestamp: now,
        ),
      );
    }

    if (avgTemp != null) {
      final isHeatStress = avgTemp > 26.0;
      alerts.add(
        FarmNotification(
          id: 'ecostress-${_dayKey(now)}',
          title: isHeatStress
              ? 'NASA ECOSTRESS: Canopy Heat Stress Alert'
              : 'NASA ECOSTRESS: Normal Thermal Envelope',
          description:
              'Mean air temperature at ${avgTemp.toStringAsFixed(1)}°C over $windowLabel. Crop transpiration rates are ${isHeatStress ? 'elevated above optimal threshold' : 'within normal seasonal range'}.',
          category: 'climate',
          severity: isHeatStress
              ? NotificationSeverity.warning
              : NotificationSeverity.info,
          isCritical: false,
          source: 'NASA ECOSTRESS',
          metricValue: '${avgTemp.toStringAsFixed(1)}°C',
          recommendation: isHeatStress
              ? 'Consider agroforestry or temporary shading during peak solar noon.'
              : 'Optimal temperature profile for vegetative photosynthesis.',
          timestamp: now,
        ),
      );
    }

    if (dailyPrecip != null) {
      final isDrySpell = dailyPrecip < 1.0;
      alerts.add(
        FarmNotification(
          id: 'gpm-rain-${_dayKey(now)}',
          title: isDrySpell
              ? 'NASA GPM: Below-Average Rainfall Window'
              : 'NASA GPM: Rainfall Recharge Window',
          description:
              'Measured precipitation averaged ${dailyPrecip.toStringAsFixed(1)} mm/day in $region across $windowLabel. ${isDrySpell ? 'Soil water recharge is lagging behind crop demand.' : 'Rainfall is replenishing the root zone.'}',
          category: 'climate',
          severity: isDrySpell
              ? NotificationSeverity.warning
              : NotificationSeverity.success,
          isCritical: false,
          source: 'NASA GPM',
          metricValue: '${dailyPrecip.toStringAsFixed(1)} mm/day',
          recommendation: isDrySpell
              ? 'Prioritise mulching and defer nitrogen top-dressing until soil moisture recovers.'
              : 'Time split fertilizer applications with the current rainfall to improve nutrient uptake.',
          timestamp: now,
        ),
      );
    }

    return alerts;
  }

  /// Averages finite daily values, ignoring NASA's -999 fill values.
  double? _meanValid(dynamic series) {
    if (series is! Map) {
      return null;
    }
    final values = series.values
        .whereType<num>()
        .map((v) => v.toDouble())
        .where((v) => v > -900)
        .toList();
    if (values.isEmpty) {
      return null;
    }
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _formatNasaDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  String _shortDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$d/$m';
  }

  String _dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Loads persisted read ids and marks matching alerts as read before counts
  /// are recomputed, so the badge reflects real unread alerts across refreshes.
  Future<List<FarmNotification>> _applyReadState(
    List<FarmNotification> items,
  ) async {
    final readIds = await _loadReadIds();
    final list = items
        .map((n) => readIds.contains(n.id) ? n.copyWith(isRead: true) : n)
        .toList();
    _updateCounts(list);
    return list;
  }

  /// Persists every alert in [items] as read and zeroes the live counters.
  Future<void> markAllRead(Iterable<FarmNotification> items) async {
    final ids = items.map((n) => n.id).toSet();
    final merged = {...await _loadReadIds(), ...ids}.toList()..sort();
    final trimmed = merged.length > _maxStoredReadIds
        ? merged.sublist(merged.length - _maxStoredReadIds)
        : merged;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readIdsKey, trimmed);
    } catch (e) {
      debugPrint('Failed to persist notification read state: $e');
    }

    unreadCountNotifier.value = 0;
    criticalCountNotifier.value = 0;
  }

  Future<Set<String>> _loadReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_readIdsKey) ?? const <String>[]).toSet();
    } catch (e) {
      debugPrint('Failed to load notification read state: $e');
      return <String>{};
    }
  }

  void _updateCounts(List<FarmNotification> items) {
    final unread = items.where((n) => !n.isRead).length;
    final critical = items.where((n) => n.isCritical && !n.isRead).length;
    unreadCountNotifier.value = unread;
    criticalCountNotifier.value = critical;
  }
}
