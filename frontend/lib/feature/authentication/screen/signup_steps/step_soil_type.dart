import 'package:flutter/material.dart';
import 'package:mwandu/core/theme/variables.dart';

import 'step_container.dart';

class StepSoilTypePage extends StatelessWidget {
  final TextEditingController soilTypeController;
  final TextEditingController soilTextureController;

  const StepSoilTypePage({
    super.key,
    required this.soilTypeController,
    required this.soilTextureController,
  });

  @override
  Widget build(BuildContext context) {
    return StepContainer(
      tag: 'Step 7 of 10 • Soil Profile',
      heading: 'Confirm soil classification',
      description: 'Pre-populated directly from NASA agroclimatology satellite observations. You may refine these values.',
      child: Column(
        children: [
          CarbonFormField(
            label: 'Main Soil Type *',
            hint: 'e.g. Humic Nitisol / Clay Loam',
            controller: soilTypeController,
            autofocus: true,
          ),
          const SizedBox(height: Spacing.v24px15remSpacing06),
          CarbonFormField(
            label: 'Soil Texture',
            hint: 'e.g. Loamy or Clayey',
            controller: soilTextureController,
          ),
        ],
      ),
    );
  }
}
