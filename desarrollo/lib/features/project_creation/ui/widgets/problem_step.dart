import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/project_creation_controller.dart';

/// Paso 3: qué problema resuelve el proyecto.
class ProblemStep extends StatelessWidget {
  const ProblemStep({super.key, required this.controller});

  final ProjectCreationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Define el problema', style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '¿Qué necesidad o desafío identificaste en tu entorno universitario?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: controller.problemField,
          minLines: 8,
          maxLines: 12,
          hintText: 'Describe el problema que quieres resolver...',
          onChanged: (value) => controller.problem.value = value,
        ),
      ],
    );
  }
}
