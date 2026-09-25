import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_form_actions.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../viewmodels/project_creation_controller.dart';
import '../widgets/review_section_card.dart';

/// Resumen de la propuesta antes de publicarla. Cada bloque devuelve al
/// paso del asistente que lo llenó.
class ProjectReviewPage extends StatelessWidget {
  const ProjectReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectCreationController controller = Get.find();
    final theme = Theme.of(context);

    void editStep(int step) {
      controller.goToStep(step);
      Get.back();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Revisar proyecto')),
      body: Obx(() {
        final draft = controller.draft;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          children: [
            Text(
              'Verifica los datos de tu propuesta antes de publicarla en la '
              'comunidad universitaria.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ReviewSectionCard(
              title: 'Información básica',
              onEdit: () => editStep(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(draft.description),
                ],
              ),
            ),
            ReviewSectionCard(
              title: 'Problema',
              onEdit: () => editStep(3),
              child: Text(draft.problem),
            ),
            ReviewSectionCard(
              title: 'Objetivo y Alcance',
              onEdit: () => editStep(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.objective),
                  if (draft.scope.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(draft.scope),
                  ],
                ],
              ),
            ),
            ReviewSectionCard(
              title: 'Etapa',
              onEdit: () => editStep(1),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppTagChip(label: draft.stage ?? 'Sin definir'),
              ),
            ),
            ReviewSectionCard(
              title: 'Equipo y Roles',
              onEdit: () => editStep(5),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  const Chip(label: Text('1 Creador')),
                  Chip(label: Text('Máx: ${draft.maxMembers} integrantes')),
                  Chip(label: Text('Dedicación: ${draft.availability}')),
                  if (draft.coLeader != null)
                    Chip(label: Text('Co-líder: ${draft.coLeader!.name}')),
                  for (final role in draft.roles) Chip(label: Text(role)),
                ],
              ),
            ),
            ReviewSectionCard(
              title: 'Etiquetas y Portada',
              onEdit: () => editStep(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (draft.tags.isEmpty)
                    Text(
                      'Sin etiquetas.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        for (final tag in draft.tags)
                          Text(
                            '#$tag',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  if (draft.coverUrl == null)
                    Text(
                      'Sin portada.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.xs),
                          child: Image.network(
                            draft.coverUrl!,
                            width: 72,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(draft.coverName ?? '')),
                      ],
                    ),
                ],
              ),
            ),
            ReviewSectionCard(
              title: 'Referencias',
              onEdit: () => editStep(6),
              child: draft.links.isEmpty
                  ? Text('Sin enlaces.', style: theme.textTheme.bodySmall)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final link in draft.links)
                          Text(
                            link,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(
        () => AppFormActions(
          secondaryLabel: 'Atrás',
          onSecondary: Get.back,
          primaryLabel: 'Publicar proyecto',
          primaryColor: AppSemanticColors.success,
          onPrimaryColor: AppSemanticColors.onSuccess,
          onPrimary: controller.isPublishing.value
              ? null
              : () async {
                  final project = await controller.publish(); 
                  Get.offNamed(
                    AppRoutes.createProjectSuccess,
                    arguments: project,
                  );
                },
        ),
      ),
    );
  }
}
