import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_project_cover.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../domain/models/project_detail.dart';

/// Portada, título, etiquetas y autoría: la parte del detalle que se ve
/// igual en las tres pestañas.
class ProjectDetailHeader extends StatelessWidget {
  const ProjectDetailHeader({
    super.key,
    required this.detail,
    required this.likeCount,
    required this.likedByMe,
    required this.onToggleLike,
  });

  final ProjectDetail detail;
  final int likeCount;
  final bool likedByMe;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final creator = detail.creator;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppProjectCover(projectId: detail.projectId, projectName: detail.name),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      detail.name,
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  if (detail.stage != null) AppTagChip(label: detail.stage!),
                ],
              ),
              if (detail.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final tag in detail.tags) AppTagChip(label: tag),
                  ],
                ),
              ],
              if (creator != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    AppAvatar(name: creator.name, avatarUrl: creator.avatarUrl),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Creado por ${creator.name}',
                            style: theme.textTheme.titleSmall,
                          ),
                          if (creator.subtitle != null)
                            Text(
                              creator.subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  IconButton(
                    onPressed: onToggleLike,
                    tooltip: likedByMe ? 'Quitar me gusta' : 'Me gusta',
                    icon: Icon(
                      likedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: likedByMe ? colors.primary : null,
                    ),
                  ),
                  Text('$likeCount', style: theme.textTheme.titleSmall),
                ],
              ),
              const Divider(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}
