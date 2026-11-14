import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mwandu/core/services/nasa_service.dart';
import 'package:mwandu/core/theme/variables.dart';

class StepOsmLocationPage extends StatelessWidget {
  final LatLng selectedLocation;
  final MapController mapController;
  final bool isQueryingNasa;
  final String? nasaStatusMessage;
  final NasaSoilProfile? nasaProfile;
  final void Function(TapPosition tapPosition, LatLng point) onMapTapped;

  const StepOsmLocationPage({
    super.key,
    required this.selectedLocation,
    required this.mapController,
    required this.isQueryingNasa,
    required this.nasaStatusMessage,
    required this.nasaProfile,
    required this.onMapTapped,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.v24px15remSpacing06,
        vertical: Spacing.v24px15remSpacing06,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'STEP 6 OF 10 • GEOSPATIAL & OPENSTREETMAP',
            style: TextStyle(
              color: tokens.interactive,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Spacing.v8px05remSpacing03),
          Text(
            'Pin your farm on OpenStreetMap',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: Spacing.v8px05remSpacing03),
          Text(
            'Tap anywhere on the OpenStreetMap below to place your farm pin. The coordinates automatically query the NASA POWER satellite API for soil telemetry.',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Spacing.v24px15remSpacing06),

          // Interactive OpenStreetMap Container
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: tokens.borderSubtle01, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: selectedLocation,
                    initialZoom: 11.0,
                    onTap: onMapTapped,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.kilimo.carbon_signup',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selectedLocation,
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.location_on,
                            color: tokens.interactive,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating zoom controls
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    children: [
                      _buildMapIconButton(
                        icon: Icons.add,
                        tokens: tokens,
                        onTap: () {
                          mapController.move(
                            selectedLocation,
                            mapController.camera.zoom + 1,
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      _buildMapIconButton(
                        icon: Icons.remove,
                        tokens: tokens,
                        onTap: () {
                          mapController.move(
                            selectedLocation,
                            mapController.camera.zoom - 1,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Instructions strip
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: tokens.layer01.withValues(alpha: 0.92),
                    child: Text(
                      'Tap map anywhere to update pin & trigger NASA query',
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.v16px1remSpacing05),

          // Coordinates Card
          Container(
            padding: const EdgeInsets.all(Spacing.v12px075remSpacing04),
            color: tokens.layer01,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LATITUDE',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        selectedLocation.latitude.toStringAsFixed(4),
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: tokens.borderSubtle01),
                const SizedBox(width: Spacing.v12px075remSpacing04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LONGITUDE',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        selectedLocation.longitude.toStringAsFixed(4),
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.v12px075remSpacing04),

          // NASA Satellite Telemetry Card
          Container(
            padding: const EdgeInsets.all(Spacing.v12px075remSpacing04),
            decoration: BoxDecoration(
              color: tokens.layer01,
              border: Border(
                left: BorderSide(
                  color: isQueryingNasa
                      ? tokens.interactive
                      : tokens.supportSuccess,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isQueryingNasa)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.satellite_alt,
                        color: tokens.supportSuccess,
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      'NASA POWER SATELLITE API',
                      style: TextStyle(
                        color: tokens.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  nasaStatusMessage ?? 'Ready to query NASA soil telemetry',
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
                if (nasaProfile != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildChip('Soil: ${nasaProfile!.soilType}', tokens),
                      _buildChip(
                        'Elev: ${nasaProfile!.elevationMeters.toStringAsFixed(0)}m',
                        tokens,
                      ),
                      if (nasaProfile!.surfaceWetness != null)
                        _buildChip(
                          'Wetness: ${nasaProfile!.surfaceWetness!.toStringAsFixed(2)}',
                          tokens,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required AppThemeTokens tokens,
    required VoidCallback onTap,
  }) {
    return Material(
      color: tokens.layer01,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: tokens.borderSubtle01),
          ),
          child: Icon(icon, color: tokens.textPrimary, size: 20),
        ),
      ),
    );
  }

  Widget _buildChip(String text, AppThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: tokens.background,
      child: Text(
        text,
        style: TextStyle(
          color: tokens.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
