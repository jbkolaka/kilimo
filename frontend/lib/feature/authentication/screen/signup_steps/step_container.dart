import 'package:flutter/material.dart';
import 'package:mwandu/core/theme/variables.dart';

/// Reusable Carbon container for single-field signup steps.
class StepContainer extends StatelessWidget {
  final String tag;
  final String heading;
  final String description;
  final Widget child;

  const StepContainer({
    super.key,
    required this.tag,
    required this.heading,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.v24px15remSpacing06,
        vertical: Spacing.v32px2remSpacing07,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tag.toUpperCase(),
            style: TextStyle(
              color: tokens.interactive,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: Spacing.v8px05remSpacing03),
          Text(
            heading,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: Spacing.v8px05remSpacing03),
          Text(
            description,
            style: TextStyle(
              color: tokens.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: Spacing.v32px2remSpacing07),
          child,
        ],
      ),
    );
  }
}

/// Carbon-styled Text Field with accessible labels and clear interactive borders.
class CarbonFormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final bool autofocus;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const CarbonFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.autofocus = false,
    this.suffixIcon,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: tokens.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: Spacing.v8px05remSpacing03),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          autofocus: autofocus,
          keyboardType: keyboardType,
          onChanged: onChanged,
          cursorColor: tokens.interactive,
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: tokens.field01,
            hintText: hint,
            hintStyle: TextStyle(color: tokens.textPlaceholder, fontSize: 15),
            suffixIcon: suffixIcon,
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: tokens.borderStrong01, width: 1.5),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: tokens.borderStrong01, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: tokens.borderInteractive,
                width: 2.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacing.v16px1remSpacing05,
              vertical: Spacing.v16px1remSpacing05,
            ),
          ),
        ),
      ],
    );
  }
}
