import 'package:mwandu/feature/notification/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwandu/core/components/bottom_app_bar/index.dart';
import 'package:mwandu/core/theme/variables.dart';
import 'package:mwandu/feature/authentication/bloc/auth_bloc.dart';
import 'package:mwandu/feature/authentication/model/user_model.dart';
import 'package:mwandu/feature/notification/notification_screen.dart';
import 'package:mwandu/feature/setting/setting_screen.dart';
import 'package:mwandu/feature/home/widgets/nasa_climate_chart_card.dart';

class HomeScreen extends StatefulWidget {
  final bool? enableAutoNasaFetch;

  const HomeScreen({
    super.key,
    this.enableAutoNasaFetch = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return PopScope(
      canPop: false,
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/signin',
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          UserModel? user;
          if (state is Authenticated) {
            user = state.user;
          }

          final List<Widget> pages = [
            _buildDashboardBody(context, tokens, user),
            const NotificationScreen(),
            const SettingScreen(),
          ];

          return Scaffold(
            backgroundColor: tokens.background,
            body: IndexedStack(index: _selectedTabIndex, children: pages),
            bottomNavigationBar: ValueListenableBuilder<int>(
              valueListenable: NotificationService.unreadCountNotifier,
              builder: (context, unreadCount, _) {
                return CBottomAppBar(
                  currentIndex: _selectedTabIndex,
                  onTap: (index) {
                    setState(() => _selectedTabIndex = index);
                  },
                  items: [
                    const CBottomAppBarItem(
                      label: 'Home',
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      tooltip: 'Kilimo Farm Dashboard',
                    ),
                    CBottomAppBarItem(
                      label: 'Notifications',
                      icon: const Icon(Icons.notifications_outlined),
                      selectedIcon: const Icon(Icons.notifications),
                      badgeCount: unreadCount,
                      tooltip: 'Live Alerts and Satellite Telemetry',
                    ),
                    const CBottomAppBarItem(
                      label: 'Settings',
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      tooltip: 'Theme and Profile Settings',
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardBody(
    BuildContext context,
    AppThemeTokens tokens,
    UserModel? user,
  ) {
    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: tokens.layer01,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.eco_rounded, color: tokens.backgroundBrand, size: 24),
            const SizedBox(width: Spacing.v12px075remSpacing04),
            Text(
              'Kilimo Farm Dashboard',
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              context.themeMode.isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: tokens.textSecondary,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => context.toggleBrightness(),
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(tokens.buttonPrimary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.v24px15remSpacing06),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Farmer Banner Card
                      Container(
                        padding: const EdgeInsets.all(
                          Spacing.v24px15remSpacing06,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.layer01,
                          border: Border.all(color: tokens.borderSubtle01),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: tokens.backgroundBrand,
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : 'F',
                                style: TextStyle(
                                  color: tokens.textOnColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: Spacing.v24px15remSpacing06),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      color: tokens.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: Spacing.v4px025remSpacing02,
                                  ),
                                  Text(
                                    user.farmName,
                                    style: TextStyle(
                                      color: tokens.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: Spacing.v4px025remSpacing02,
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.place_outlined,
                                        size: 16,
                                        color: tokens.interactive,
                                      ),
                                      const SizedBox(
                                        width: Spacing.v4px025remSpacing02,
                                      ),
                                      Text(
                                        '${user.location.countyRegion} • ${user.farmSizeAcres.toStringAsFixed(1)} Acres',
                                        style: TextStyle(
                                          color: tokens.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.v24px15remSpacing06),

                      // Location & Coordinates Card
                      Container(
                        padding: const EdgeInsets.all(
                          Spacing.v16px1remSpacing05,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.layer01,
                          border: Border.all(color: tokens.borderSubtle01),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OPENSTREETMAP LOCATION',
                              style: TextStyle(
                                color: tokens.interactive,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              'Latitude',
                              user.location.latitude.toStringAsFixed(4),
                              tokens,
                            ),
                            _buildInfoRow(
                              'Longitude',
                              user.location.longitude.toStringAsFixed(4),
                              tokens,
                            ),
                            if (user.location.elevationMeters != null)
                              _buildInfoRow(
                                'Elevation',
                                '${user.location.elevationMeters!.toStringAsFixed(1)} m',
                                tokens,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.v24px15remSpacing06),

                      // Soil Profile Card
                      Container(
                        padding: const EdgeInsets.all(
                          Spacing.v16px1remSpacing05,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.layer01,
                          border: Border.all(color: tokens.borderSubtle01),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NASA SATELLITE SOIL PROFILE',
                              style: TextStyle(
                                color: tokens.interactive,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (user.soilAttributes.mainSoilType != null)
                              _buildInfoRow(
                                'Main Soil Type',
                                user.soilAttributes.mainSoilType!,
                                tokens,
                              ),
                            if (user.soilAttributes.soilTexture != null)
                              _buildInfoRow(
                                'Texture',
                                user.soilAttributes.soilTexture!,
                                tokens,
                              ),
                            if (user.soilAttributes.customPH != null)
                              _buildInfoRow(
                                'pH Level',
                                user.soilAttributes.customPH!.toStringAsFixed(
                                  1,
                                ),
                                tokens,
                              ),
                            if (user.soilAttributes.customOMPct != null)
                              _buildInfoRow(
                                'Organic Matter',
                                '${user.soilAttributes.customOMPct!.toStringAsFixed(1)}%',
                                tokens,
                              ),
                            if (user.soilAttributes.drainageCapacity != null)
                              _buildInfoRow(
                                'Drainage',
                                user.soilAttributes.drainageCapacity!,
                                tokens,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.v24px15remSpacing06),

                      // NASA Agroclimate & Soil Line Chart
                      NasaClimateChartCard(
                        latitude: user.location.latitude,
                        longitude: user.location.longitude,
                        enableAutoFetch: widget.enableAutoNasaFetch ?? true,
                      ),
                      const SizedBox(height: Spacing.v24px15remSpacing06),

                      // Crops History Card
                      Container(
                        padding: const EdgeInsets.all(
                          Spacing.v16px1remSpacing05,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.layer01,
                          border: Border.all(color: tokens.borderSubtle01),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CROPS CULTIVATED',
                              style: TextStyle(
                                color: tokens.interactive,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: user.currentCropHistory
                                  .map(
                                    (crop) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      color: tokens.background,
                                      child: Text(
                                        crop.toUpperCase(),
                                        style: TextStyle(
                                          color: tokens.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, AppThemeTokens tokens) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.v8px05remSpacing03),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: tokens.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
