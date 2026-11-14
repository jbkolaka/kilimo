import 'package:flutter/material.dart';

import 'step_container.dart';

class StepFarmSizePage extends StatelessWidget {
  final TextEditingController controller;

  const StepFarmSizePage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      tag: 'Step 5 of 10 • Farm Dimensions',
      heading: 'How large is your farm in acres?',
      description: 'Acreage allows our agro-AI engine to compute seed densities, irrigation needs, and carbon credits.',
      child: CarbonFormField(
        label: 'Total Farm Size (Acres) *',
        hint: 'e.g. 5.0',
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: true,
      ),
    );
  }
}
