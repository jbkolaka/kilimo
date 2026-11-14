import 'package:flutter/material.dart';

import 'step_container.dart';

class StepEmailPage extends StatelessWidget {
  final TextEditingController controller;

  const StepEmailPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      tag: 'Step 2 of 10 • Credentials',
      heading: 'What is your email address?',
      description: 'We will use this email for authentication, soil test sync, and precision harvest advisories.',
      child: CarbonFormField(
        label: 'Email Address *',
        hint: 'farmer@example.com',
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
      ),
    );
  }
}
