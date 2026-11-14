import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwandu/core/theme/variables.dart';
import 'package:mwandu/feature/authentication/bloc/auth_bloc.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String farmerName = 'Farmer';
        String farmerEmail = '';
        String farmName = '';
        if (state is Authenticated) {
          farmerName = state.user.name;
          farmerEmail = state.user.email;
          farmName = state.user.farmName;
        }

        return Scaffold(
          backgroundColor: tokens.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: tokens.layer01,
            elevation: 0,
            title: Text(
              'Settings',
              style: TextStyle(
                color: tokens.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(Spacing.v16px1remSpacing05),
            children: [
              // Profile Section
              Material(
                color: tokens.layer01,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.v16px1remSpacing05),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: tokens.backgroundBrand,
                        child: Text(
                          farmerName.isNotEmpty
                              ? farmerName[0].toUpperCase()
                              : 'K',
                          style: TextStyle(
                            color: tokens.textOnColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: Spacing.v16px1remSpacing05),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              farmerName,
                              style: TextStyle(
                                color: tokens.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (farmerEmail.isNotEmpty)
                              Text(
                                farmerEmail,
                                style: TextStyle(
                                  color: tokens.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            if (farmName.isNotEmpty)
                              Text(
                                farmName,
                                style: TextStyle(
                                  color: tokens.interactive,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.v16px1remSpacing05),

              // Carbon Theme Section
              _buildSectionHeader('APPEARANCE & THEME', tokens),
              const SizedBox(height: Spacing.v8px05remSpacing03),
              Material(
                color: tokens.layer01,
                child: SwitchListTile(
                  title: Text(
                    'Dark Theme (Carbon Gray 100)',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    context.themeMode.isDark
                        ? 'Dark mode enabled'
                        : 'Light mode enabled',
                    style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                  ),
                  value: context.themeMode.isDark,
                  activeThumbColor: tokens.interactive,
                  onChanged: (_) => context.toggleBrightness(),
                ),
              ),
              const SizedBox(height: Spacing.v16px1remSpacing05),

              // NASA & Geospatial Settings
              _buildSectionHeader('SATELLITE & DATA SOURCES', tokens),
              const SizedBox(height: Spacing.v8px05remSpacing03),
              Material(
                color: tokens.layer01,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.satellite_alt,
                        color: tokens.interactive,
                        size: 20,
                      ),
                      title: Text(
                        'NASA POWER API',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Endpoint: power.larc.nasa.gov (AG Community)',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        color: tokens.supportSuccess.withValues(alpha: 0.15),
                        child: Text(
                          'CONNECTED',
                          style: TextStyle(
                            color: tokens.supportSuccess,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1, color: tokens.borderSubtle01),
                    ListTile(
                      leading: Icon(
                        Icons.map_outlined,
                        color: tokens.textPrimary,
                        size: 20,
                      ),
                      title: Text(
                        'Map Provider',
                        style: TextStyle(
                          color: tokens.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'OpenStreetMap Standard Carto Tiles',
                        style: TextStyle(
                          color: tokens.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.v24px15remSpacing06),

              // Sign Out Button
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  icon: Icon(
                    Icons.logout,
                    size: 18,
                    color: tokens.supportError,
                  ),
                  label: Text(
                    'Sign Out of Kilimo',
                    style: TextStyle(
                      color: tokens.supportError,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: tokens.supportError),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  onPressed: () {
                    context.read<AuthBloc>().add(const SignOutRequested());
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, AppThemeTokens tokens) {
    return Text(
      title,
      style: TextStyle(
        color: tokens.interactive,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}
