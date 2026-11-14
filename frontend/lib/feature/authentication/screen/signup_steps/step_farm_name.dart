import 'package:flutter/material.dart';

import 'step_container.dart';

class StepFarmNamePage extends StatelessWidget {
  final TextEditingController controller;

  const StepFarmNamePage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      tag: 'Step 4 of 10 • Farm Profile',
      heading: 'What is your farm or co-op name?',
      description: 'Give your farm a distinctive name for multi-field zoning and crop yield tracking.',
      child: CarbonFormField(
        label: 'Farm or Cooperative Name *',
        hint: 'e.g. Green Highlands Organic Farm',
        controller: controller,
        autofocus: true,
      ),
    );
  }
}
