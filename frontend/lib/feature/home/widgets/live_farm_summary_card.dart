import 'package:flutter/material.dart';
import 'package:mwandu/core/services/nasa_service.dart';
import 'package:mwandu/core/shared/styles/colors.style.dart';
import 'package:mwandu/core/theme/variables.dart';

/// Compact dashboard card showing the latest NASA POWER daily weather for the
/// farm and whether each saved crop is inside its temperature tolerance.
class LiveFarmSummaryCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final List<String> crops;
  final String farmName;
  final NasaService? nasaService;

  const LiveFarmSummaryCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.crops = const [],
    this.farmName = '',
    this.nasaService,
  });

  @override
  State<LiveFarmSummaryCard> createState() => _LiveFarmSummaryCardState();
}

class _LiveFarmSummaryCardState extends State<LiveFarmSummaryCard> {
  late final NasaService _nasaService;
  FarmWeatherSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _nasaService = widget.nasaService ?? NasaService();
    _load();
  }

  @override
  void didUpdateWidget(covariant LiveFarmSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cropsChanged = widget.crops.join(',') != oldWidget.crops.join(',');
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude ||
        widget.farmName != oldWidget.farmName ||
        cropsChanged) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final summary = await _nasaService.fetchFarmWeatherSummary(
      latitude: widget.latitude,
      longitude: widget.longitude,
      crops: widget.crops,
      farmName: widget.farmName,
    );
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(Spacing.v16px1remSpacing05),
      decoration: BoxDecoration(
        color: tokens.layer01,
        border: Border.all(color: tokens.borderSubtle01),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? tokens.supportWarning
                      : tokens.supportSuccess,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Spacing.v8px05remSpacing03),
              Expanded(
                child: Text(
                  'LIVE NASA WEATHER',
                  style: TextStyle(
                    color: tokens.interactive,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (!_isLoading)
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: tokens.textSecondary,
                  ),
                  tooltip: 'Refresh live weather',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _load,
                ),
            ],
          ),
          const SizedBox(height: Spacing.v8px05remSpacing03),
          if (_isLoading)
            _buildLoading(tokens)
          else if (_summary == null)
            _buildUnavailable(tokens)
          else
            _buildSummary(tokens, _summary!),
        ],
      ),
    );
  }

  Widget _buildLoading(AppThemeTokens tokens) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(tokens.interactive),
            ),
          ),
          const SizedBox(width: Spacing.v12px075remSpacing04),
          Expanded(
            child: Text(
              'Fetching the latest NASA POWER observations…',
              style: TextStyle(color: tokens.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailable(AppThemeTokens tokens) {
    return Row(
      children: [
        Icon(Icons.cloud_off_outlined, size: 18, color: tokens.textSecondary),
        const SizedBox(width: Spacing.v8px05remSpacing03),
        Expanded(
          child: Text(
            'Live weather is unavailable right now.',
            style: TextStyle(color: tokens.textSecondary, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: _load,
          style: TextButton.styleFrom(
            foregroundColor: tokens.interactive,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Retry', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildSummary(AppThemeTokens tokens, FarmWeatherSummary summary) {
    final weather = summary.weather;
    final crops = summary.crops;
    final affected = crops.where((crop) => !crop.isOk).toList();
    final isCritical = affected.any((crop) => (crop.exceedanceC ?? 0) >= 3.0);

    final Color statusColor;
    final IconData statusIcon;
    final String statusText;
    if (crops.isEmpty) {
      statusColor = tokens.textSecondary;
      statusIcon = Icons.info_outline;
      statusText = 'Add your crops to see a temperature risk check.';
    } else if (affected.isEmpty) {
      statusColor = tokens.supportSuccess;
      statusIcon = Icons.check_circle_outline;
      statusText =
          'All ${crops.length} crop(s) within temperature tolerance.';
    } else {
      statusColor = isCritical ? tokens.supportError : tokens.supportWarning;
      statusIcon = Icons.warning_amber_rounded;
      statusText =
          '${affected.length} of ${crops.length} crop(s) outside temperature tolerance.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(statusIcon, size: 16, color: statusColor),
            const SizedBox(width: Spacing.v8px05remSpacing03),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  color: tokens.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.v12px075remSpacing04),
        Row(
          children: [
            Expanded(
              child: _metricTile(
                tokens: tokens,
                label: 'Mean temp',
                value: '${weather.meanTempC.toStringAsFixed(1)}°C',
                detail:
                    'H ${weather.maxTempC.toStringAsFixed(1)}° · L ${weather.minTempC.toStringAsFixed(1)}°',
                icon: Icons.thermostat_outlined,
                color: CColors.red50,
              ),
            ),
            const SizedBox(width: Spacing.v8px05remSpacing03),
            Expanded(
              child: _metricTile(
                tokens: tokens,
                label: 'Soil moisture',
                value: weather.soilMoistureM3M3 == null
                    ? '—'
                    : '${(weather.soilMoistureM3M3! * 100).toStringAsFixed(0)}%',
                detail: weather.soilMoistureM3M3 == null
                    ? 'No data'
                    : 'Surface wetness',
                icon: Icons.water_drop_outlined,
                color: CColors.teal40,
              ),
            ),
            const SizedBox(width: Spacing.v8px05remSpacing03),
            Expanded(
              child: _metricTile(
                tokens: tokens,
                label: 'Rain / day',
                value: weather.precipitationMMDay == null
                    ? '—'
                    : '${weather.precipitationMMDay!.toStringAsFixed(1)} mm',
                detail: weather.precipitationMMDay == null
                    ? 'No data'
                    : 'Daily average',
                icon: Icons.cloud_queue_outlined,
                color: CColors.blue50,
              ),
            ),
          ],
        ),
        if (crops.isNotEmpty) ...[
          const SizedBox(height: Spacing.v12px075remSpacing04),
          Wrap(
            spacing: Spacing.v8px05remSpacing03,
            runSpacing: Spacing.v8px05remSpacing03,
            children: crops.map((crop) => _cropChip(tokens, crop)).toList(),
          ),
        ],
        const SizedBox(height: Spacing.v12px075remSpacing04),
        Text(
          '${weather.source} · ${weather.window}',
          style: TextStyle(color: tokens.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _metricTile({
    required AppThemeTokens tokens,
    required String label,
    required String value,
    required String detail,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.v8px05remSpacing03,
        vertical: Spacing.v8px05remSpacing03,
      ),
      decoration: BoxDecoration(
        color: tokens.layer02,
        border: Border(
          left: BorderSide(color: color, width: 3.0),
          top: BorderSide(color: tokens.borderSubtle01),
          right: BorderSide(color: tokens.borderSubtle01),
          bottom: BorderSide(color: tokens.borderSubtle01),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: Spacing.v4px025remSpacing02),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.textSecondary, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.v4px025remSpacing02),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.v2px0125remSpacing01),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tokens.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _cropChip(AppThemeTokens tokens, CropTemperatureRisk crop) {
    final exceedance = crop.exceedanceC ?? 0;
    final color = crop.isOk
        ? tokens.supportSuccess
        : exceedance >= 3.0
        ? tokens.supportError
        : tokens.supportWarning;
    final status = crop.isOk
        ? 'OK'
        : crop.status == 'heat_stress'
        ? 'Heat +${exceedance.toStringAsFixed(1)}°C'
        : 'Cold −${exceedance.toStringAsFixed(1)}°C';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.v8px05remSpacing03,
        vertical: Spacing.v4px025remSpacing02,
      ),
      decoration: BoxDecoration(
        color: tokens.layer02,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Spacing.v4px025remSpacing02),
          Text(
            crop.name,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: Spacing.v4px025remSpacing02),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
