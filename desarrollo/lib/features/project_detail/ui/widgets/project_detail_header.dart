import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../domain/models/project_detail.dart';

/// Portada, título, etiquetas y autoría: la parte del detalle que se ve
/// igual en las tres pestañas.
class ProjectDetailHeader extends StatelessWidget {
  const ProjectDetailHeader({super.key, required this.detail});

  final ProjectDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final creator = detail.creator;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cover(imageUrl: detail.coverUrl),
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
              const Divider(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget placeholder() => Container(
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.image_outlined,
        size: AppSpacing.xl,
        color: colors.onSurfaceVariant,
      ),
    );

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: imageUrl == null
          ? placeholder()
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholder(),
            ),
    );
  }
}
