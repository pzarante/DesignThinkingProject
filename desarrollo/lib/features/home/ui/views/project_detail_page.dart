import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../domain/models/project.dart';
import '../../domain/models/project_application.dart';
import '../viewmodels/project_application_controller.dart';

/// Full-screen detail view for a single [Project].
///
/// Receives the project via [Get.arguments] as a [Project] instance.
class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({super.key});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late final Project project;
  late final ProjectApplicationController applicationController;

  @override
  void initState() {
    super.initState();
    project = Get.arguments as Project;
    applicationController = Get.find<ProjectApplicationController>();
    applicationController.loadForProject(project.id);
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () => _showApplicationForm(context),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Postularme al proyecto'),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Postulaciones', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Obx(() => applicationController.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : _ApplicationsList(
                        controller: applicationController,
                        applications: applicationController.applications,
                      )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showApplicationForm(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final motivationController = TextEditingController();
    final availabilityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Postularme', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: motivationController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Motivación'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Cuéntale al equipo cómo puedes aportar'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: availabilityController,
                decoration: const InputDecoration(
                  labelText: 'Disponibilidad',
                  hintText: '6 horas por semana',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Indica tu disponibilidad'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Enviar postulación'),
              ),
            ],
          ),
        ),
      ),
    );
    if (submitted == true) {
      await applicationController.submit(
        ProjectApplication(
          id: 'application-${DateTime.now().millisecondsSinceEpoch}',
          projectId: project.id,
          applicantName: 'María García',
          applicantEmail: 'maria@uni.edu',
          motivation: motivationController.text.trim(),
          availability: availabilityController.text.trim(),
        ),
      );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Postulación enviada.')),
        );
      }
    }
    motivationController.dispose();
    availabilityController.dispose();
  }
}

class _ApplicationsList extends StatelessWidget {
  const _ApplicationsList({
    required this.controller,
    required this.applications,
  });

  final ProjectApplicationController controller;
  final List<ProjectApplication> applications;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) return const Text('Aún no hay postulaciones.');
    return Column(
      children: [
        for (final application in applications)
          Card(
            child: ListTile(
              title: Text(application.applicantName),
              subtitle: Text(
                '${application.motivation}\nDisponibilidad: ${application.availability}',
              ),
              isThreeLine: true,
              trailing: application.status == ProjectApplicationStatus.pending
                  ? PopupMenuButton<ProjectApplicationStatus>(
                      tooltip: 'Resolver postulación',
                      onSelected: (status) =>
                          controller.updateStatus(application.id, status),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: ProjectApplicationStatus.accepted,
                          child: Text('Aceptar'),
                        ),
                        PopupMenuItem(
                          value: ProjectApplicationStatus.rejected,
                          child: Text('Rechazar'),
                        ),
                      ],
                    )
                  : Text(_statusLabel(application.status)),
            ),
          ),
      ],
    );
  }

  String _statusLabel(ProjectApplicationStatus status) {
    switch (status) {
      case ProjectApplicationStatus.accepted:
        return 'Aceptada';
      case ProjectApplicationStatus.rejected:
        return 'Rechazada';
      case ProjectApplicationStatus.pending:
        return 'Pendiente';
    }
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
                errorBuilder: (errorContext, error, stackTrace) =>
                  _placeholder(),
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
