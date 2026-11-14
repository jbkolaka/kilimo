import 'package:flutter/material.dart';
import 'package:mwandu/core/theme/variables.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final notifications = [
      (
        title: 'NASA Satellite Alert: Soil Moisture Drop',
        description: 'Surface wetness (GWETTOP) dropped to 0.42 in Rongai sector. Supplemental drip irrigation recommended for maize rows.',
        time: '12m ago',
        isCritical: true,
        icon: Icons.water_drop_outlined,
      ),
      (
        title: 'Precision Fertilizer Advisory',
        description: 'Based on pH 6.2 and volcanic loam characteristics, top-dress CAN at 50kg/acre prior to anticipated precipitation.',
        time: '2h ago',
        isCritical: false,
        icon: Icons.science_outlined,
      ),
      (
        title: 'OpenStreetMap Boundary Verified',
        description: 'Your 5.0-acre coordinates have been successfully indexed for seasonal vegetation index (NDVI) monitoring.',
        time: 'Yesterday',
        isCritical: false,
        icon: Icons.map_outlined,
      ),
      (
        title: 'Carbon Credit Baseline Sync',
        description: 'Organic matter level at 3.5% qualifies your farm for soil carbon sequestration reward tier A.',
        time: '3 days ago',
        isCritical: false,
        icon: Icons.eco_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        backgroundColor: tokens.layer01,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: tokens.textSecondary, size: 20),
            tooltip: 'Mark all as read',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(Spacing.v16px1remSpacing05),
        itemCount: notifications.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: Spacing.v12px075remSpacing04),
        itemBuilder: (context, index) {
          final item = notifications[index];

          return Container(
            padding: const EdgeInsets.all(Spacing.v16px1remSpacing05),
            decoration: BoxDecoration(
              color: tokens.layer01,
              border: Border(
                left: BorderSide(
                  color: item.isCritical
                      ? tokens.supportError
                      : tokens.interactive,
                  width: 4,
                ),
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
                  color: item.isCritical
                      ? tokens.supportError.withValues(alpha: 0.12)
                      : tokens.backgroundBrand.withValues(alpha: 0.12),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: item.isCritical
                        ? tokens.supportError
                        : tokens.interactive,
                  ),
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
                            item.time,
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
