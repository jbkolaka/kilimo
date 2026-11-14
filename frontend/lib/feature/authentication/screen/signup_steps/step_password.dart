import 'package:flutter/material.dart';
import 'package:mwandu/core/theme/variables.dart';

import 'step_container.dart';

class StepPasswordPage extends StatefulWidget {
  final TextEditingController controller;

  const StepPasswordPage({super.key, required this.controller});

  @override
  State<StepPasswordPage> createState() => _StepPasswordPageState();
}

class _StepPasswordPageState extends State<StepPasswordPage> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return StepContainer(
      tag: 'Step 3 of 10 • Security',
      heading: 'Create a secure password',
      description: 'Enter a password with at least 6 characters to keep your agricultural records safe.',
      child: CarbonFormField(
        label: 'Password (min 6 characters) *',
        hint: '••••••••',
        controller: widget.controller,
        obscureText: _obscure,
        autofocus: true,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: tokens.iconSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
