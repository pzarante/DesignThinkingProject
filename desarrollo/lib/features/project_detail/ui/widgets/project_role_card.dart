import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/project_role.dart';

/// Tarjeta de un rol que el proyecto busca cubrir, con sus cupos.
class ProjectRoleCard extends StatelessWidget {
  const ProjectRoleCard({super.key, required this.role});

  final ProjectRole role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(role.title, style: theme.textTheme.titleMedium),
                ),
                _SlotsBadge(role: role),
              ],
            ),
            if (role.skills.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
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
    );
  }
}

class _SlotsBadge extends StatelessWidget {
  const _SlotsBadge({required this.role});

  final ProjectRole role;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = role.isOpen
        ? '${role.openSlots}/${role.totalSlots} cupos'
        : 'Cerrado';
    final bg = role.isOpen
        ? colors.secondaryContainer
        : colors.surfaceContainerHighest;
    final fg = role.isOpen
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
