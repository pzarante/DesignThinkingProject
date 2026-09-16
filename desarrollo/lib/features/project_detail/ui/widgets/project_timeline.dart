import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/project_milestone.dart';

/// Cronograma vertical: un punto por paso, unidos por una línea.
class ProjectTimeline extends StatelessWidget {
  const ProjectTimeline({super.key, required this.milestones});

  final List<ProjectMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < milestones.length; index++)
          _TimelineEntry(
            milestone: milestones[index],
            isLast: index == milestones.length - 1,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({required this.milestone, required this.isLast});

  final ProjectMilestone milestone;
  final bool isLast;

  Color _color(ColorScheme colors) => switch (milestone.status) {
    MilestoneStatus.completado => AppSemanticColors.success,
    MilestoneStatus.enProgreso => colors.primary,
    MilestoneStatus.pendiente => colors.outline,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color(theme.colorScheme);
    final isPending = milestone.status == MilestoneStatus.pendiente;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  color: theme.colorScheme.surface,
                ),
                child: milestone.status == MilestoneStatus.completado
                    ? Icon(Icons.check, size: 14, color: color)
                    : milestone.status == MilestoneStatus.enProgreso
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                      )
                    : null,
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: color)),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isPending
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  Text(
                    milestone.dateLabel == null
                        ? milestone.statusLabel
                        : '${milestone.statusLabel} · ${milestone.dateLabel}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: milestone.status == MilestoneStatus.enProgreso
                          ? color
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
