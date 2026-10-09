import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Frase apagada para cuando una sección concreta no tiene nada que listar.
///
/// Es el escalón intermedio entre no enseñar nada —que deja el título de la
/// sección suelto sobre un hueco— y [AppEmptyState], que ocupa media pantalla
/// y aquí taparía a las secciones de al lado.
class AppEmptyNote extends StatelessWidget {
  const AppEmptyNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
