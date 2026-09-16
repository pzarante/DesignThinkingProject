import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/widgets/app_success_view.dart';
import '../../../community_creation/ui/viewmodels/community_creation_controller.dart';
import '../../../home/domain/models/project.dart';
import '../viewmodels/project_creation_controller.dart';

/// Confirmación de publicación. Recibe el [Project] creado por argumentos.
class ProjectCreatedPage extends StatelessWidget {
  const ProjectCreatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectCreationController controller = Get.find();
    final project = Get.arguments as Project;

    return Scaffold(
      body: AppSuccessView(
        title: '¡Proyecto creado!',
        message:
            'Tu proyecto ${project.name} ha sido publicado exitosamente en la '
            'plataforma y ya es visible para toda la comunidad universitaria.',
        primaryLabel: 'Ver proyecto',
        onPrimary: () => Get.offNamedUntil(
          AppRoutes.projectDetail,
          ModalRoute.withName(AppRoutes.home),
          arguments: project,
        ),
        secondaryActions: [
          TextButton(
            onPressed: () => Get.offAllNamed(AppRoutes.home),
            child: const Text('Volver al inicio'),
          ),
          // Solo cuando el asistente se abrió desde el formulario de
          // comunidad: se vuelve allí con el proyecto ya vinculado.
          if (controller.startedFromCommunity.value)
            TextButton(
              onPressed: () {
                Get.find<CommunityCreationController>().linkCreatedProject(
                  project,
                );
                Get.until(ModalRoute.withName(AppRoutes.createCommunity));
              },
              child: const Text('Volver a la comunidad'),
            ),
        ],
      ),
    );
  }
}
