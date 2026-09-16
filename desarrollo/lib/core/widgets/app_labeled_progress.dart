import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Barra de avance con su etiqueta y el porcentaje a la derecha.
class AppLabeledProgress extends StatelessWidget {
  const AppLabeledProgress({
    super.key,
    required this.label,
    required this.percent,
  });

  final String label;

  /// Avance de 0 a 100.
  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(label, style: theme.textTheme.titleSmall)),
            Text(
              '$percent%',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0, 1).toDouble(),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
