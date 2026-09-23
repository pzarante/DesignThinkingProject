import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_labeled_progress.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/models/project_comment.dart';
import '../../domain/models/project_detail.dart';
import 'comments_section.dart';
import 'project_timeline.dart';

/// Pestaña "Detalles": la propuesta completa del proyecto.
///
/// Las secciones que el proyecto todavía no ha llenado (cronograma, hitos,
/// enlaces) simplemente no se dibujan, en vez de mostrarse vacías.
class DetailsTab extends StatelessWidget {
  const DetailsTab({
    super.key,
    required this.detail,
    required this.comments,
    required this.isSendingComment,
    required this.onSubmitComment,
  });

  final ProjectDetail detail;
  final List<ProjectComment> comments;
  final bool isSendingComment;
  final ValueChanged<String> onSubmitComment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.description != null)
          _Section(title: 'Descripción', body: detail.description!),
        if (detail.problem != null)
          _Section(title: 'El Problema', body: detail.problem!),
        if (detail.objective != null)
          _Section(title: 'Objetivo', body: detail.objective!),
        if (detail.scope != null)
          _Section(title: 'Alcance', body: detail.scope!),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: AppLabeledProgress(
            label: 'Progreso general',
            percent: detail.progressPercent,
          ),
        ),
        if (detail.timeline.isNotEmpty) ...[
          const AppSectionHeader(title: 'Cronograma'),
          ProjectTimeline(milestones: detail.timeline),
        ],
        if (detail.activeMilestones.isNotEmpty) ...[
          const AppSectionHeader(title: 'Hitos activos'),
          for (final milestone in detail.activeMilestones)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppLabeledProgress(
                  label: milestone.title,
                  percent: milestone.progressPercent,
                ),
              ),
            ),
        ],
        if (detail.links.isNotEmpty) ...[
          const AppSectionHeader(title: 'Enlaces y referencias'),
          for (final link in detail.links)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                link,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
        if (detail.tags.isNotEmpty) ...[
          const AppSectionHeader(title: 'Etiquetas'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in detail.tags) Chip(label: Text('#$tag')),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        CommentsSection(
          comments: comments,
          isSending: isSendingComment,
          onSubmit: onSubmitComment,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: title),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}
