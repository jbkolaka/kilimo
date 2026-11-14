import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwandu/core/theme/variables.dart';
import 'package:mwandu/feature/authentication/bloc/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();

    // Trigger auth check after slight delay for smooth visual presentation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.read<AuthBloc>().add(const AppStarted());
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else if (state is Unauthenticated || state is AuthFailure) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/signin',
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: tokens.background,
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: Spacing.v96px6remSpacing12,
                    height: Spacing.v96px6remSpacing12,
                    decoration: BoxDecoration(
                      color: tokens.backgroundBrand,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.backgroundBrand.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 54,
                      color: tokens.textOnColor,
                    ),
                  ),
                  const SizedBox(height: Spacing.v24px15remSpacing06),
                  Text(
                    'KILIMO',
                    style: TextStyle(
                      color: tokens.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: Spacing.v8px05remSpacing03),
                  Text(
                    'PRECISION AGRICULTURE SYSTEM',
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: Spacing.v48px3remSpacing09),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tokens.interactive,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
