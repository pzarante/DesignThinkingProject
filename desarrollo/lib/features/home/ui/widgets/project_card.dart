import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/app_keys.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_project_cover.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../domain/models/project.dart';

/// Large project card with a cover, its labels, and the team size.
class ProjectCard extends StatelessWidget {
  ProjectCard({Key? key, required this.project, this.onTap})
    : super(key: key ?? AppKeys.projectCard(project.id));

  final Project project;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            onTap ??
            () => Get.toNamed(AppRoutes.projectDetail, arguments: project),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppProjectCover(
              projectId: project.id,
              projectName: project.name,
              isNew: project.isNew,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (project.tags.isNotEmpty)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AppTagChip(label: project.tags.first),
                          ),
                        ),
                      if (project.stage != null)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: AppTagChip(label: project.stage!),
                          ),
                        ),
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
