import 'package:flutter/material.dart';

import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

/// Pantalla de confirmación: marca verde, mensaje y acciones de salida.
class AppSuccessView extends StatelessWidget {
  const AppSuccessView({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryActions = const [],
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;

  /// Enlaces bajo el botón principal, p. ej. "Volver al inicio".
  final List<Widget> secondaryActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppSemanticColors.successContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 44,
                color: AppSemanticColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 3),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimary,
                child: Text(primaryLabel),
              ),
            ),
            ...secondaryActions,
          ],
        ),
      ),
    );
  }
}
