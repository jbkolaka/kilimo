import 'package:flutter/material.dart';

import 'step_container.dart';

class StepCropsPage extends StatelessWidget {
  final TextEditingController controller;

  const StepCropsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      tag: 'Step 9 of 10 • Agronomic History',
      heading: 'What crops do you cultivate?',
      description: 'List currently grown or intended crops separated by commas. This seeds crop rotation and AI fertilizer advisories.',
      child: CarbonFormField(
        label: 'Crops List *',
        hint: 'e.g. maize, beans, sorghum, coffee',
        controller: controller,
        autofocus: true,
      ),
    );
  }
}
