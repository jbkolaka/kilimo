import 'package:flutter/material.dart';
import 'package:mwandu/core/components/index.dart';
import 'package:mwandu/core/services/nasa_service.dart';
import 'package:mwandu/core/shared/styles/colors.style.dart';
import 'package:mwandu/core/theme/variables.dart';

/// A Carbon Design System card displaying ~1 year of NASA POWER agroclimatology
/// time series (Soil Moisture, Temperature, Precipitation) using [CLineChart]
/// and a [CSelect] granularity dropdown switcher (Monthly, Weekly, Daily, Yearly).
class NasaClimateChartCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final NasaTimeInterval initialInterval;
  final NasaService? nasaService;
  final bool? enableAutoFetch;

  const NasaClimateChartCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.initialInterval = NasaTimeInterval.monthly,
    this.nasaService,
    this.enableAutoFetch = true,
  });

  @override
  State<NasaClimateChartCard> createState() => _NasaClimateChartCardState();
}

class _NasaClimateChartCardState extends State<NasaClimateChartCard> {
  late final NasaService _nasaService;
  late NasaTimeInterval _selectedInterval;
  late NasaTimeSeriesData _data;
  bool _isLoading = false;
  String? _selectedPointDetails;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _nasaService = widget.nasaService ?? NasaService();
    _selectedInterval = widget.initialInterval;
    _data = _nasaService.getCalibratedTimeSeries(
      interval: _selectedInterval,
      latitude: widget.latitude,
      longitude: widget.longitude,
    );

    if (widget.enableAutoFetch ?? true) {
      _loadData(_selectedInterval);
    }
  }

  @override
  void didUpdateWidget(covariant NasaClimateChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialInterval != oldWidget.initialInterval) {
      _selectedInterval = widget.initialInterval;
      _data = _nasaService.getCalibratedTimeSeries(
        interval: _selectedInterval,
        latitude: widget.latitude,
        longitude: widget.longitude,
      );
    }
  }

  Future<void> _loadData(NasaTimeInterval interval) async {
    setState(() => _isLoading = true);
    try {
      final freshData = await _nasaService.fetchTimeSeries(
        latitude: widget.latitude,
        longitude: widget.longitude,
        interval: interval,
      );
      if (mounted) {
        setState(() {
          _data = freshData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onIntervalChanged(NasaTimeInterval? newInterval) {
    if (newInterval == null || newInterval == _selectedInterval) return;
    setState(() {
      _selectedInterval = newInterval;
      _selectedPointDetails = null;
      _data = _nasaService.getCalibratedTimeSeries(
        interval: newInterval,
        latitude: widget.latitude,
        longitude: widget.longitude,
      );
    });

    if (widget.enableAutoFetch ?? true) {
      _loadData(newInterval);
    }
  }

  String _getXAxisLabel(NasaTimeInterval interval) {
    return switch (interval) {
      NasaTimeInterval.monthly => '12-Month Observation Timeline',
      NasaTimeInterval.weekly => '52-Week Agricultural Cycle',
      NasaTimeInterval.daily => 'Duration: Range 1–7 & 7–14 Days',
      NasaTimeInterval.yearly => 'Multi-Year Climate Baseline (2021-2024)',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Compute key statistics for pills
    double avgMoisture = 0.0;
    double avgTemp = 0.0;
    double totalPrecip = 0.0;

    for (final s in _data.series) {
      if (s.name.contains('Moisture') && s.points.isNotEmpty) {
        avgMoisture =
            s.points.map((p) => p.y).reduce((a, b) => a + b) / s.points.length;
      } else if (s.name.contains('Temperature') && s.points.isNotEmpty) {
        avgTemp =
            s.points.map((p) => p.y).reduce((a, b) => a + b) / s.points.length;
      } else if (s.name.contains('Precipitation') && s.points.isNotEmpty) {
        totalPrecip = s.points.map((p) => p.y).reduce((a, b) => a + b);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: tokens.layer01,
        border: Border.all(color: tokens.borderSubtle01),
      ),
      padding: const EdgeInsets.all(Spacing.v16px1remSpacing05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Title and Granularity Selector
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          size: 16,
                          color: tokens.interactive,
                        ),
                        const SizedBox(width: Spacing.v8px05remSpacing03),
                        Expanded(
                          child: Text(
                            'NASA SATELLITE CLIMATE & SOIL TRENDS',
                            style: TextStyle(
                              color: tokens.interactive,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.v4px025remSpacing02),
                    Text(
                      'Multi-Metric 1-Year Agroclimatology',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tokens.interactive,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.v12px075remSpacing04),

          // Granularity Selector with Carbon CSelect
          Row(
            children: [
              Expanded(
                child: CSelect<NasaTimeInterval>(
                  size: CSelectSize.sm,
                  labelText: 'Timeframe Granularity',
                  value: _selectedInterval,
                  items: const [
                    CSelectItem(
                      value: NasaTimeInterval.monthly,
                      label: 'Monthly (1-Year Aggregate)',
                    ),
                    CSelectItem(
                      value: NasaTimeInterval.weekly,
                      label: 'Weekly (52 Weeks)',
                    ),
                    CSelectItem(
                      value: NasaTimeInterval.daily,
                      label: 'Daily (Last 14 Days: 1-7 & 7-14)',
                    ),
                    CSelectItem(
                      value: NasaTimeInterval.yearly,
                      label: 'Yearly (Multi-Year Climate)',
                    ),
                  ],
                  onChanged: _onIntervalChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.v16px1remSpacing05),

          // Metric Summary Badges / Pills
          Wrap(
            spacing: Spacing.v8px05remSpacing03,
            runSpacing: Spacing.v8px05remSpacing03,
            children: [
              _buildMetricPill(
                label: 'Moisture',
                value: '${avgMoisture.toStringAsFixed(1)}%',
                color: CColors.teal40,
                tokens: tokens,
                icon: Icons.water_drop_outlined,
              ),
              _buildMetricPill(
                label: 'Mean Temp',
                value: '${avgTemp.toStringAsFixed(1)}°C',
                color: CColors.red50,
                tokens: tokens,
                icon: Icons.thermostat_outlined,
              ),
              _buildMetricPill(
                label: 'Total Precip',
                value: '${totalPrecip.toStringAsFixed(0)} mm',
                color: CColors.blue50,
                tokens: tokens,
                icon: Icons.cloud_queue_outlined,
              ),
            ],
          ),
          const SizedBox(height: Spacing.v16px1remSpacing05),

          // Line Chart Canvas - Flush to Edge with Zero Padding
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: Spacing.v4px025remSpacing02,
            ),
            decoration: BoxDecoration(
              color: tokens.background,
              border: Border.all(color: tokens.borderSubtle01),
            ),
            child: CLineChart(
              key: ValueKey(
                'chart_${_selectedInterval.name}_${_data.xLabels.length}',
              ),
              props: CLineChartProps(
                series: _data.series,
                xAxisLabels: _data.xLabels,
                xAxisTickIndices: _data.tickIndices,
                removePadding: true,
                variant: CLineChartVariant.grouped,
                filledArea: true,
                areaOpacity: 0.12,
                curveSmooth: true,
                showLegend: true,
                showGridLines: true,
                showAxes: true,
                showDataPoints: true,
                height: 260,
                xAxisLabel: _getXAxisLabel(_selectedInterval),
                yAxisLabel: 'Value (%, °C, mm)',
                onPointTap: (series, point) {
                  final xIndex = point.x.toInt();
                  final label = (xIndex >= 0 && xIndex < _data.xLabels.length)
                      ? (_selectedInterval == NasaTimeInterval.daily
                            ? 'Day ${_data.xLabels[xIndex]}'
                            : _data.xLabels[xIndex])
                      : 'Point ${point.x.toInt()}';
                  setState(() {
                    _selectedPointDetails =
                        '${series.name} • $label: ${point.label ?? point.y.toStringAsFixed(1)}';
                  });
                },
              ),
            ),
          ),

          // Interactive Data Point Highlight
          if (_selectedPointDetails != null) ...[
            const SizedBox(height: Spacing.v12px075remSpacing04),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.v12px075remSpacing04,
                vertical: Spacing.v8px05remSpacing03,
              ),
              decoration: BoxDecoration(
                color: tokens.layerSelected01,
                border: Border(
                  left: BorderSide(color: tokens.borderInteractive, width: 3.0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 16,
                    color: tokens.interactive,
                  ),
                  const SizedBox(width: Spacing.v8px05remSpacing03),
                  Expanded(
                    child: Text(
                      _selectedPointDetails!,
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 14,
                      color: tokens.iconPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Clear',
                    onPressed: () =>
                        setState(() => _selectedPointDetails = null),
                  ),
                ],
              ),
            ),
          ],

          // Satellite Insight Summary Box
          const SizedBox(height: Spacing.v16px1remSpacing05),
          Container(
            padding: const EdgeInsets.all(Spacing.v12px075remSpacing04),
            decoration: BoxDecoration(
              color: tokens.layer02,
              border: Border.all(color: tokens.borderSubtle01),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.satellite_alt_outlined,
                  size: 18,
                  color: tokens.interactive,
                ),
                const SizedBox(width: Spacing.v12px075remSpacing04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AGRONOMIC SATELLITE INSIGHT',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _data.summary,
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Expand / Collapse Full Table Breakdown
          const SizedBox(height: Spacing.v12px075remSpacing04),
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Spacing.v4px025remSpacing02,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isExpanded
                        ? 'Hide Numerical Breakdown'
                        : 'Show Numerical Breakdown',
                    style: TextStyle(
                      color: tokens.interactive,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: tokens.interactive,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: Spacing.v8px05remSpacing03),
            _buildNumericalBreakdown(tokens),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
    required AppThemeTokens tokens,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.v12px075remSpacing04,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: Spacing.v4px025remSpacing02),
          Text(
            '$label: ',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericalBreakdown(AppThemeTokens tokens) {
    if (_data.series.isEmpty || _data.xLabels.isEmpty) {
      return const SizedBox.shrink();
    }

    final moisture = _data.series
        .where((s) => s.name.contains('Moisture'))
        .firstOrNull;
    final temp = _data.series
        .where((s) => s.name.contains('Temperature'))
        .firstOrNull;
    final precip = _data.series
        .where((s) => s.name.contains('Precipitation'))
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: tokens.layer02,
        border: Border.all(color: tokens.borderSubtle01),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 36,
          horizontalMargin: 12,
          columnSpacing: 16,
          columns: const [
            DataColumn(
              label: Text(
                'Period',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Moisture (%)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: CColors.teal40,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Temp (°C)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: CColors.red50,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Precip (mm)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: CColors.blue50,
                ),
              ),
            ),
          ],
          rows: List.generate(_data.xLabels.length, (i) {
            final mVal = (moisture != null && i < moisture.points.length)
                ? moisture.points[i].y.toStringAsFixed(1)
                : '-';
            final tVal = (temp != null && i < temp.points.length)
                ? temp.points[i].y.toStringAsFixed(1)
                : '-';
            final pVal = (precip != null && i < precip.points.length)
                ? precip.points[i].y.toStringAsFixed(1)
                : '-';

            final periodLabel = _selectedInterval == NasaTimeInterval.daily
                ? 'Day ${_data.xLabels[i]}'
                : _data.xLabels[i];

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    periodLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(Text(mVal, style: const TextStyle(fontSize: 12))),
                DataCell(Text(tVal, style: const TextStyle(fontSize: 12))),
                DataCell(Text(pVal, style: const TextStyle(fontSize: 12))),
              ],
            );
          }),
        ),
      ),
    );
  }
}
