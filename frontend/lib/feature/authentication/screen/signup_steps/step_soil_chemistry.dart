import 'package:flutter/material.dart';
import 'package:mwandu/core/theme/variables.dart';

import 'step_container.dart';

class StepSoilChemistryPage extends StatelessWidget {
  final TextEditingController phController;
  final TextEditingController omController;
  final TextEditingController drainageController;

  const StepSoilChemistryPage({
    super.key,
    required this.phController,
    required this.omController,
    required this.drainageController,
  });

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      tag: 'Step 8 of 10 • Soil Chemistry',
      heading: 'Enter soil pH & organic matter',
      description: 'NASA calibrated values for chemical baseline. Adjust if you have recent soil lab test results.',
      child: Column(
        children: [
          CarbonFormField(
            label: 'Soil pH (3.0 - 10.0) *',
            hint: 'e.g. 6.2',
            controller: phController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
          ),
          const SizedBox(height: Spacing.v24px15remSpacing06),
          CarbonFormField(
            label: 'Organic Matter %',
            hint: 'e.g. 3.5',
            controller: omController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: Spacing.v24px15remSpacing06),
          CarbonFormField(
            label: 'Drainage Capacity',
            hint: 'e.g. Well-drained',
            controller: drainageController,
          ),
        ],
      ),
    );
  }
}
