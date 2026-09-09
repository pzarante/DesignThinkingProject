import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../domain/models/project.dart';

/// Full-screen detail view for a single [Project].
///
/// Receives the project via [Get.arguments] as a [Project] instance.
class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final project = Get.arguments as Project;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _CoverSliverAppBar(project: project, colors: colors),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tags + Stage row
                Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    for (final tag in project.tags) AppTagChip(label: tag),
                    if (project.stage != null)
                      AppTagChip(label: project.stage!),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Project name
                Text(project.name, style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSpacing.sm),

                // Member count
                Row(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${project.memberCount} integrante${project.memberCount == 1 ? '' : 's'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Description
                if (project.description != null) ...[
                  Text('Descripción', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    project.description!,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Placeholder CTA
                FilledButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Solicitud de unión próximamente.'),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Unirme al proyecto'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverSliverAppBar extends StatelessWidget {
  const _CoverSliverAppBar({required this.project, required this.colors});

  final Project project;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: project.imageUrl != null
            ? Image.network(
                project.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: colors.surfaceContainerHighest,
        child: Icon(
          Icons.image_outlined,
          size: AppSpacing.xl,
          color: colors.onSurfaceVariant,
        ),
      );
}
