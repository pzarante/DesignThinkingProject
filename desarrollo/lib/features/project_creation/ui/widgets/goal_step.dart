import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/project_creation_controller.dart';

/// Paso 4: objetivo general y alcance.
class GoalStep extends StatelessWidget {
  const GoalStep({super.key, required this.controller});

  final ProjectCreationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Objetivo general',
          isRequired: true,
          controller: controller.objectiveField,
          minLines: 4,
          maxLines: 6,
          hintText: '¿Qué quieres lograr con el proyecto?',
          onChanged: (value) => controller.objective.value = value,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Alcance del proyecto',
          controller: controller.scopeField,
          minLines: 3,
          maxLines: 5,
          hintText: '¿Hasta dónde llega esta primera fase?',
          helperText:
              'Define límites claros de tiempo, recursos y espacio de prueba.',
          onChanged: (value) => controller.scope.value = value,
        ),
      ],
    );
  }
}
