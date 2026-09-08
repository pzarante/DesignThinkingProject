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
            _Cover(imageUrl: project.imageUrl, isNew: project.isNew),
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
  const _Cover({this.imageUrl, this.isNew = false});

  final String? imageUrl;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        if (imageUrl == null)
          _placeholder(colors)
        else
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: colors.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  _placeholder(colors),
            ),
          ),
        if (isNew)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: _NewBadge(),
          ),
      ],
    );
  }

  Widget _placeholder(ColorScheme colors) {
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

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        'NUEVO',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onTertiaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
