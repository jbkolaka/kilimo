import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mwandu/core/services/nasa_service.dart';
import 'package:mwandu/core/theme/variables.dart';

class StepReviewPage extends StatelessWidget {
  final String name;
  final String email;
  final String farmName;
  final String farmSize;
  final LatLng location;
  final String elevation;
  final String soilType;
  final String soilTexture;
  final String ph;
  final String om;
  final String drainage;
  final String crops;
  final NasaSoilProfile? nasaProfile;
  final bool isLoading;

  const StepReviewPage({
    super.key,
    required this.name,
    required this.email,
    required this.farmName,
    required this.farmSize,
    required this.location,
    required this.elevation,
    required this.soilType,
    required this.soilTexture,
    required this.ph,
    required this.om,
    required this.drainage,
    required this.crops,
    required this.nasaProfile,
    required this.isLoading,
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
            'STEP 10 OF 10 • FINAL CONFIRMATION',
            style: TextStyle(
              color: tokens.interactive,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Spacing.v8px05remSpacing03),
          Text(
            'Review farm registration',
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: Spacing.v8px05remSpacing03),
          Text(
            'Verify your account credentials, OpenStreetMap coordinates, and NASA satellite soil baseline.',
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Spacing.v24px15remSpacing06),

          _buildReviewCard(
            title: 'FARMER & ACCOUNT',
            tokens: tokens,
            items: [('Name', name), ('Email', email)],
          ),
          const SizedBox(height: Spacing.v12px075remSpacing04),

          _buildReviewCard(
            title: 'FARM PROFILE',
            tokens: tokens,
            items: [('Farm Name', farmName), ('Acreage', '$farmSize Acres')],
          ),
          const SizedBox(height: Spacing.v12px075remSpacing04),

          _buildReviewCard(
            title: 'OPENSTREETMAP LOCATION',
            tokens: tokens,
            items: [
              ('Latitude', location.latitude.toStringAsFixed(4)),
              ('Longitude', location.longitude.toStringAsFixed(4)),
              ('Elevation', '$elevation m'),
            ],
          ),
          const SizedBox(height: Spacing.v12px075remSpacing04),

          _buildReviewCard(
            title: 'NASA SATELLITE SOIL PROFILE',
            tokens: tokens,
            items: [
              ('Soil Type', soilType),
              ('Texture', soilTexture),
              ('pH Level', ph),
              ('Organic Matter', '$om%'),
              ('Drainage', drainage),
              ('Data Source', nasaProfile?.dataSource ?? 'NASA Baseline'),
            ],
          ),
          const SizedBox(height: Spacing.v12px075remSpacing04),

          _buildReviewCard(
            title: 'CROPS GROWN',
            tokens: tokens,
            items: [('Crops', crops)],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required String title,
    required AppThemeTokens tokens,
    required List<(String, String)> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(Spacing.v16px1remSpacing05),
      color: tokens.layer01,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: tokens.interactive,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.$1,
                    style: TextStyle(color: tokens.textSecondary, fontSize: 13),
                  ),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
