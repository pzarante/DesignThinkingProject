import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../home/domain/models/project_application.dart';
import '../../../home/ui/viewmodels/project_application_controller.dart';

/// Postulaciones recibidas por el proyecto, con su resolución.
///
/// Solo se muestra en la configuración: es gestión del equipo, no parte de
/// lo que ve quien visita el proyecto.
class ApplicationsList extends StatelessWidget {
  const ApplicationsList({super.key, required this.controller});

  final ProjectApplicationController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final applications = controller.applications;
      if (applications.isEmpty) {
        return Text(
          'Aún no hay postulaciones.',
          style: Theme.of(context).textTheme.bodyMedium,
        );
      }

      return Column(
        children: [
          for (final application in applications)
            Card(
              child: ListTile(
                title: Text(application.applicantName),
                subtitle: Text(
                  '${application.motivation}\n'
                  'Disponibilidad: ${application.availability}',
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
    });
  }

  String _statusLabel(ProjectApplicationStatus status) => switch (status) {
    ProjectApplicationStatus.accepted => 'Aceptada',
    ProjectApplicationStatus.rejected => 'Rechazada',
    ProjectApplicationStatus.pending => 'Pendiente',
  };
}
