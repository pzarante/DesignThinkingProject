import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';

/// Pestaña "Publicaciones".
///
/// El muro del proyecto es una feature aparte: aquí solo queda el hueco y,
/// para el equipo, el punto de entrada a crear la primera publicación.
class PostsTab extends StatelessWidget {
  const PostsTab({super.key, required this.canPublish, required this.onCreate});

  final bool canPublish;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: AppEmptyState(
        icon: Icons.forum_outlined,
        title: 'Aún no hay publicaciones',
        message: canPublish
            ? 'Comparte avances, prototipos o preguntas con quienes siguen '
                  'el proyecto.'
            : 'Cuando el equipo publique algo, aparecerá aquí.',
        action: canPublish
            ? FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Crear publicación'),
              )
            : null,
      ),
    );
  }
}
