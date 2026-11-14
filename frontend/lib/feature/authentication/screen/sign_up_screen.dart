import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mwandu/core/components/button/index.dart';
import 'package:mwandu/core/components/progress_bar/index.dart';
import 'package:mwandu/core/components/progress_indicator/index.dart';
import 'package:mwandu/core/services/nasa_service.dart';
import 'package:mwandu/core/theme/variables.dart';
import 'package:mwandu/feature/authentication/bloc/auth_bloc.dart';
import 'package:mwandu/feature/authentication/model/user_model.dart';

import 'signup_steps/index.dart';

/// Carbon-designed multi-page mobile signup with:
/// - Each page in its own dedicated file under `signup_steps/`
/// - Data asked one field at a time
/// - OpenStreetMap tap-to-pin location selection
/// - NASA POWER agroclimatology & soil satellite telemetry
/// - Carbon Progress Indicator & Progress Bar using design system tokens
class SignUpScreen extends StatefulWidget {
  final bool enableAutoNasaInit;

  const SignUpScreen({super.key, this.enableAutoNasaInit = true});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final PageController _pageController = PageController();
  final ScrollController _progressScrollController = ScrollController();
  final MapController _mapController = MapController();
  final NasaService _nasaService = NasaService();

  int _currentStep = 0;
  static const int _totalSteps = 10;

  // Form Field Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmSizeController = TextEditingController(text: '5.0');

  // Location & Geospatial
  LatLng _selectedLocation = const LatLng(-0.3031, 36.0800);
  final String _selectedRegion = 'Nakuru';
  final _subCountyController = TextEditingController(text: 'Rongai');
  final _elevationController = TextEditingController(text: '1850.0');

  // Soil Attributes (Updated by NASA Satellite API)
  final _soilTypeController = TextEditingController(text: 'Clay Loam');
  final _soilTextureController = TextEditingController(text: 'Loamy');
  final _phController = TextEditingController(text: '6.2');
  final _omController = TextEditingController(text: '3.5');
  final _drainageController = TextEditingController(text: 'Well-drained');
  final _cropHistoryController = TextEditingController(text: 'maize, beans');

  // NASA Query State
  bool _isQueryingNasa = false;
  NasaSoilProfile? _nasaProfile;
  String? _nasaStatusMessage;

  // UI Error State
  String? _currentStepError;

  final List<String> _stepTitles = const [
    'Farmer Name',
    'Email Address',
    'Password',
    'Farm Name',
    'Farm Size',
    'Map Location',
    'Soil Type',
    'Soil Chemistry',
    'Crops Grown',
    'Review',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.enableAutoNasaInit) {
      _queryNasaSoil(_selectedLocation.latitude, _selectedLocation.longitude);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressScrollController.dispose();
    _mapController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _farmNameController.dispose();
    _farmSizeController.dispose();
    _subCountyController.dispose();
    _elevationController.dispose();
    _soilTypeController.dispose();
    _soilTextureController.dispose();
    _phController.dispose();
    _omController.dispose();
    _drainageController.dispose();
    _cropHistoryController.dispose();
    super.dispose();
  }

  Future<void> _queryNasaSoil(double lat, double lon) async {
    setState(() {
      _isQueryingNasa = true;
      _nasaStatusMessage =
          'Connecting to NASA POWER Satellite agroclimatology...';
    });

    try {
      final profile = await _nasaService.fetchSoilProfile(
        latitude: lat,
        longitude: lon,
      );

      if (mounted) {
        setState(() {
          _nasaProfile = profile;
          _isQueryingNasa = false;
          _nasaStatusMessage =
              'NASA Telemetry Synced: ${profile.soilType} (${profile.elevationMeters.toStringAsFixed(0)}m elev)';
          _soilTypeController.text = profile.soilType;
          _soilTextureController.text = profile.soilTexture;
          _phController.text = profile.ph.toStringAsFixed(1);
          _omController.text = profile.organicMatterPct.toStringAsFixed(1);
          _drainageController.text = profile.drainage;
          _elevationController.text = profile.elevationMeters.toStringAsFixed(
            1,
          );
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isQueryingNasa = false;
          _nasaStatusMessage =
              'Using calibrated agro-ecological regional baseline';
        });
      }
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _queryNasaSoil(point.latitude, point.longitude);
  }

  bool _validateCurrentStep() {
    setState(() => _currentStepError = null);

    switch (_currentStep) {
      case 0:
        if (_nameController.text.trim().isEmpty) {
          setState(() => _currentStepError = 'Please enter your full name');
          return false;
        }
        return true;
      case 1:
        final email = _emailController.text.trim();
        if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
          setState(
            () => _currentStepError = 'Please enter a valid email address',
          );
          return false;
        }
        return true;
      case 2:
        if (_passwordController.text.length < 6) {
          setState(
            () => _currentStepError = 'Password must be at least 6 characters',
          );
          return false;
        }
        return true;
      case 3:
        if (_farmNameController.text.trim().isEmpty) {
          setState(
            () => _currentStepError = 'Please enter your farm or co-op name',
          );
          return false;
        }
        return true;
      case 4:
        final size = double.tryParse(_farmSizeController.text.trim());
        if (size == null || size <= 0) {
          setState(
            () => _currentStepError = 'Please enter a valid farm size in acres',
          );
          return false;
        }
        return true;
      case 5:
        return true;
      case 6:
        if (_soilTypeController.text.trim().isEmpty) {
          setState(
            () => _currentStepError = 'Soil type classification is required',
          );
          return false;
        }
        return true;
      case 7:
        final ph = double.tryParse(_phController.text.trim());
        if (ph == null || ph < 3 || ph > 11) {
          setState(
            () =>
                _currentStepError = 'Please enter a realistic pH (3.0 - 10.0)',
          );
          return false;
        }
        return true;
      case 8:
        if (_cropHistoryController.text.trim().isEmpty) {
          setState(() => _currentStepError = 'Please enter at least one crop');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
      _scrollProgressIndicator();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _currentStepError = null;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
      _scrollProgressIndicator();
    } else {
      Navigator.pop(context);
    }
  }

  void _scrollProgressIndicator() {
    if (_progressScrollController.hasClients) {
      final double targetOffset = (_currentStep * 110.0).clamp(
        0.0,
        _progressScrollController.position.maxScrollExtent,
      );
      _progressScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _submitRegistration() {
    final crops = _cropHistoryController.text
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    final payload = SignUpPayload(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      farmName: _farmNameController.text.trim().isEmpty
          ? '${_nameController.text.trim()} Farm'
          : _farmNameController.text.trim(),
      farmSizeAcres: double.tryParse(_farmSizeController.text.trim()) ?? 5.0,
      location: FarmLocation(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
        countyRegion: _selectedRegion,
        subCountyVillage: _subCountyController.text.trim().isEmpty
            ? 'OpenStreetMap Pin'
            : _subCountyController.text.trim(),
        elevationMeters:
            double.tryParse(_elevationController.text.trim()) ??
            _nasaProfile?.elevationMeters,
      ),
      soilAttributes: FarmSoilAttributes(
        mainSoilType: _soilTypeController.text.trim(),
        soilTexture: _soilTextureController.text.trim(),
        customPH: double.tryParse(_phController.text.trim()) ?? 6.2,
        customOMPct: double.tryParse(_omController.text.trim()) ?? 3.5,
        drainageCapacity: _drainageController.text.trim(),
      ),
      currentCropHistory: crops.isEmpty ? ['maize'] : crops,
    );

    context.read<AuthBloc>().add(SignUpSubmitted(payload));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Column(
              children: [
                // Top App Bar with Step Status
                _buildHeader(tokens),

                // Carbon Determinate Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.v16px1remSpacing05,
                  ),
                  child: CProgressBar(
                    value: ((_currentStep + 1) / _totalSteps) * 100,
                    size: CProgressBarSize.small,
                    status: CProgressBarStatus.active,
                    hideLabel: true,
                  ),
                ),

                // Carbon Progress Stepper (Scrollable Horizontally)
                _buildCarbonStepper(tokens),

                const Divider(height: 1, thickness: 1),

                // Error feedback banner
                if (_currentStepError != null || state is AuthFailure)
                  _buildErrorBanner(
                    _currentStepError ?? (state as AuthFailure).error,
                    tokens,
                  ),

                // Multi-step PageView: Each individual page file loaded here
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      StepNamePage(controller: _nameController),
                      StepEmailPage(controller: _emailController),
                      StepPasswordPage(controller: _passwordController),
                      StepFarmNamePage(controller: _farmNameController),
                      StepFarmSizePage(controller: _farmSizeController),
                      StepOsmLocationPage(
                        selectedLocation: _selectedLocation,
                        mapController: _mapController,
                        isQueryingNasa: _isQueryingNasa,
                        nasaStatusMessage: _nasaStatusMessage,
                        nasaProfile: _nasaProfile,
                        onMapTapped: _onMapTapped,
                      ),
                      StepSoilTypePage(
                        soilTypeController: _soilTypeController,
                        soilTextureController: _soilTextureController,
                      ),
                      StepSoilChemistryPage(
                        phController: _phController,
                        omController: _omController,
                        drainageController: _drainageController,
                      ),
                      StepCropsPage(controller: _cropHistoryController),
                      StepReviewPage(
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        farmName: _farmNameController.text.trim(),
                        farmSize: _farmSizeController.text.trim(),
                        location: _selectedLocation,
                        elevation: _elevationController.text.trim(),
                        soilType: _soilTypeController.text.trim(),
                        soilTexture: _soilTextureController.text.trim(),
                        ph: _phController.text.trim(),
                        om: _omController.text.trim(),
                        drainage: _drainageController.text.trim(),
                        crops: _cropHistoryController.text.trim(),
                        nasaProfile: _nasaProfile,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),

                // Bottom Action Bar (Back / Next / Register)
                _buildBottomNavigation(tokens, isLoading),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(AppThemeTokens tokens) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.v16px1remSpacing05,
        vertical: Spacing.v12px075remSpacing04,
      ),
      color: tokens.layer01,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: tokens.textPrimary, size: 20),
            onPressed: _previousStep,
            tooltip: _currentStep == 0 ? 'Back to Sign In' : 'Previous Step',
          ),
          const SizedBox(width: Spacing.v8px05remSpacing03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CARBON SIGNUP',
                  style: TextStyle(
                    color: tokens.interactive,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps: ${_stepTitles[_currentStep]}',
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarbonStepper(AppThemeTokens tokens) {
    return Container(
      color: tokens.layer01,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.v12px075remSpacing04,
        vertical: Spacing.v8px05remSpacing03,
      ),
      child: SingleChildScrollView(
        controller: _progressScrollController,
        scrollDirection: Axis.horizontal,
        child: CProgressIndicator(
          currentIndex: _currentStep,
          vertical: false,
          spaceEqually: false,
          steps: List.generate(_totalSteps, (index) {
            final isCurrent = index == _currentStep;
            final isComplete = index < _currentStep;
            return CProgressStep(
              label: '${index + 1}. ${_stepTitles[index]}',
              current: isCurrent,
              complete: isComplete,
              onTap: () {
                if (index < _currentStep) {
                  setState(() => _currentStep = index);
                  _pageController.jumpToPage(index);
                  _scrollProgressIndicator();
                }
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message, AppThemeTokens tokens) {
    return Container(
      margin: const EdgeInsets.all(Spacing.v16px1remSpacing05),
      padding: const EdgeInsets.all(Spacing.v12px075remSpacing04),
      decoration: BoxDecoration(
        color: tokens.supportError.withValues(alpha: 0.12),
        border: Border(left: BorderSide(color: tokens.supportError, width: 4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: tokens.supportError, size: 20),
          const SizedBox(width: Spacing.v12px075remSpacing04),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: tokens.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(AppThemeTokens tokens, bool isLoading) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.all(Spacing.v16px1remSpacing05),
      color: tokens.layer01,
      child: Row(
        children: [
          Expanded(
            child: CButton(
              label: _currentStep == 0 ? 'Cancel' : 'Back',
              kind: CButtonKind.secondary,
              expand: true,
              onTap: _previousStep,
            ),
          ),
          const SizedBox(width: Spacing.v12px075remSpacing04),
          Expanded(
            child: isLastStep
                ? CButton(
                    label: isLoading ? 'Registering...' : 'Register Farm',
                    kind: CButtonKind.primary,
                    expand: true,
                    enable: !isLoading,
                    onTap: _submitRegistration,
                  )
                : CButton(
                    label: 'Next',
                    kind: CButtonKind.primary,
                    expand: true,
                    onTap: _nextStep,
                  ),
          ),
        ],
      ),
    );
  }
}
