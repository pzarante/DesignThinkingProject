import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/viewer_role.dart';

/// Barra inferior del detalle.
///
/// La información del proyecto es la misma para todo el mundo; lo que cambia
/// es qué puede hacer quien mira.
class ProjectDetailActions extends StatelessWidget {
  const ProjectDetailActions({
    super.key,
    required this.viewerRole,
    required this.onConfigure,
    required this.onCreatePost,
    required this.onApply,
    required this.onSave,
    required this.onFollow,
  });

  final ViewerRole viewerRole;
  final VoidCallback onConfigure;
  final VoidCallback onCreatePost;
  final VoidCallback onApply;
  final VoidCallback onSave;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            if (viewerRole.canConfigure) ...[
              IconButton.outlined(
                tooltip: 'Configurar proyecto',
                onPressed: onConfigure,
                icon: const Icon(Icons.settings_outlined),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (!viewerRole.belongsToProject) ...[
              IconButton.outlined(
                tooltip: 'Seguir proyecto',
                onPressed: onFollow,
                icon: const Icon(Icons.favorite_border),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.outlined(
                tooltip: 'Guardar proyecto',
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_border),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: FilledButton(
                onPressed: viewerRole.belongsToProject ? onCreatePost : onApply,
                child: Text(
                  viewerRole.belongsToProject
                      ? 'Crear publicación'
                      : 'Postularme',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
