import 'package:flutter/material.dart';

import 'step_container.dart';

class StepNamePage extends StatelessWidget {
  final TextEditingController controller;

  const StepNamePage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      tag: 'Step 1 of 10 • Farmer Identity',
      heading: 'What is your full name?',
      description: 'Your name will be associated with your farm profile and agronomic baseline recommendations.',
      child: CarbonFormField(
        label: 'Farmer Full Name *',
        hint: 'e.g. Jane Mwangi',
        controller: controller,
        autofocus: true,
      ),
    );
  }
}
