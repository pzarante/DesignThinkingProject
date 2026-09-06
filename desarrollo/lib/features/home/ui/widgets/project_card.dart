import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../domain/models/project.dart';

/// Large project card with a cover, its labels, and the team size.
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project, this.onTap});

  final Project project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Cover(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (project.tags.isNotEmpty)
                        AppTagChip(label: project.tags.first),
                      if (project.stage != null)
                        AppTagChip(label: project.stage!),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(project.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${project.memberCount} Integrantes',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: colors.surfaceContainerHighest,
        child: Icon(
          Icons.image_outlined,
          size: AppSpacing.xl,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}
