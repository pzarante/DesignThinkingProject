import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../domain/models/project_application.dart';
import '../viewmodels/applicants_controller.dart';

/// Lista de postulaciones de un proyecto, solo para creador/co-líder.
/// Recibe por [Get.arguments] el projectId.
class ApplicantsPage extends StatefulWidget {
  const ApplicantsPage({super.key});

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  final ApplicantsController controller = Get.find();
  late final String projectId = Get.arguments as String;

  @override
  void initState() {
    super.initState();
    controller.load(projectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Postulantes')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.applications.isEmpty) {
          return const AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Sin postulaciones aún',
            message: 'Cuando alguien se postule, aparecerá aquí.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: controller.applications.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final application = controller.applications[index];
            return _ApplicantCard(
              application: application,
              onAccept: () => controller.accept(application),
              onReject: () => controller.reject(application),
            );
          },
        );
      }),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  const _ApplicantCard({
    required this.application,
    required this.onAccept,
    required this.onReject,
  });

  final ProjectApplication application;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = application.status == ProjectApplicationStatus.pending;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(name: application.applicantName),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.applicantName,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        application.applicantEmail,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusLabel(status: application.status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(application.motivation),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Disponibilidad: ${application.availability}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: onAccept,
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.status});

  final ProjectApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (status) {
      ProjectApplicationStatus.pending => (
        'Pendiente',
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      ProjectApplicationStatus.accepted => (
        'Aceptado',
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      ProjectApplicationStatus.rejected => (
        'Rechazado',
        colors.errorContainer,
        colors.onErrorContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
