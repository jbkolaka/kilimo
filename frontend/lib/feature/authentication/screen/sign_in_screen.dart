import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mwandu/core/theme/variables.dart';
import 'package:mwandu/feature/authentication/bloc/auth_bloc.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignInPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        SignInSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.v24px15remSpacing06,
              vertical: Spacing.v32px2remSpacing07,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
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

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(
                                Spacing.v12px075remSpacing04,
                              ),
                              decoration: BoxDecoration(
                                color: tokens.backgroundBrand,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.eco_rounded,
                                color: tokens.textOnColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: Spacing.v16px1remSpacing05),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'KILIMO',
                                  style: TextStyle(
                                    color: tokens.textPrimary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                Text(
                                  'Farmer Portal & Soil System',
                                  style: TextStyle(
                                    color: tokens.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.v32px2remSpacing07),

                        Text(
                          'Sign In',
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: Spacing.v8px05remSpacing03),
                        Text(
                          'Enter your farmer account credentials to manage soil recommendations.',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: Spacing.v24px15remSpacing06),

                        // Error message
                        if (state is AuthFailure) ...[
                          Container(
                            padding: const EdgeInsets.all(
                              Spacing.v16px1remSpacing05,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.supportError.withValues(
                                alpha: 0.15,
                              ),
                              border: Border(
                                left: BorderSide(
                                  color: tokens.supportError,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: tokens.supportError,
                                  size: 20,
                                ),
                                const SizedBox(
                                  width: Spacing.v12px075remSpacing04,
                                ),
                                Expanded(
                                  child: Text(
                                    state.error,
                                    style: TextStyle(
                                      color: tokens.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: Spacing.v24px15remSpacing06),
                        ],

                        // Email Field
                        Text(
                          'Email Address',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: Spacing.v8px05remSpacing03),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: tokens.field01,
                            hintText: 'farmer@example.com',
                            hintStyle: TextStyle(
                              color: tokens.textPlaceholder,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: tokens.textPlaceholder,
                              size: 20,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: tokens.borderStrong01,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: tokens.borderStrong01,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: tokens.borderInteractive,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Spacing.v16px1remSpacing05,
                              vertical: Spacing.v12px075remSpacing04,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Spacing.v16px1remSpacing05),

                        // Password Field
                        Text(
                          'Password',
                          style: TextStyle(
                            color: tokens.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: Spacing.v8px05remSpacing03),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                            color: tokens.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: tokens.field01,
                            hintText: '••••••••',
                            hintStyle: TextStyle(
                              color: tokens.textPlaceholder,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: tokens.textPlaceholder,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: tokens.textPlaceholder,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: tokens.borderStrong01,
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: tokens.borderStrong01,
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: tokens.borderInteractive,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Spacing.v16px1remSpacing05,
                              vertical: Spacing.v12px075remSpacing04,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: Spacing.v32px2remSpacing07),

                        // Submit Button
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _onSignInPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tokens.buttonPrimary,
                              foregroundColor: tokens.textOnColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        tokens.textOnColor,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: tokens.textOnColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: Spacing.v8px05remSpacing03,
                                      ),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: Spacing.v24px15remSpacing06),

                        // Switch to Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                color: tokens.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: Text(
                                'Register Farm',
                                style: TextStyle(
                                  color: tokens.interactive,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
