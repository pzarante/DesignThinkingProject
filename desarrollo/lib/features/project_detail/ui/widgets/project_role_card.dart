import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/project_role.dart';

/// Tarjeta de un rol que el proyecto todavía busca cubrir.
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
            Text(role.title, style: theme.textTheme.titleMedium),
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
