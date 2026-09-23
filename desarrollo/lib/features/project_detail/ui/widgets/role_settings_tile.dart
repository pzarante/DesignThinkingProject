import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/project_role.dart';

/// Fila editable de una vacante dentro de Configurar Proyecto — distinta de
/// [ProjectRoleCard] (que es la vista de solo lectura en la pestaña Equipo).
class RoleSettingsTile extends StatelessWidget {
  const RoleSettingsTile({
    super.key,
    required this.role,
    required this.onEdit,
    required this.onDelete,
  });

  final ProjectRole role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final slotsLabel = role.isOpen
        ? '${role.openSlots}/${role.totalSlots} cupos disponibles'
        : 'Cerrado · ${role.totalSlots}/${role.totalSlots} cupos';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    slotsLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: role.isOpen
                          ? colors.onSurfaceVariant
                          : colors.error,
                    ),
                  ),
                  if (role.skills.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final skill in role.skills)
                          Chip(
                            label: Text(skill),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar vacante',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Eliminar vacante',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
