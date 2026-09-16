import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Cabecera de progreso de un asistente: "PASO 2 DE 6" + "33% Completado"
/// sobre una barra de avance.
class AppWizardProgress extends StatelessWidget {
  const AppWizardProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  /// Paso actual empezando en 1.
  final int currentStep;
  final int totalSteps;

  double get _progress => currentStep / totalSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PASO $currentStep DE $totalSteps',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${(_progress * 100).round()}% Completado',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: LinearProgressIndicator(value: _progress, minHeight: 6),
        ),
      ],
    );
  }
}
