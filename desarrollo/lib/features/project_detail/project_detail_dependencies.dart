import 'package:get/get.dart';

import '../project_applications/project_applications_dependencies.dart';
import 'data/datasources/i_project_detail_source.dart';
import 'data/datasources/local/local_project_detail_source.dart';
import 'data/repositories/project_detail_repository.dart';
import 'domain/repositories/i_project_detail_repository.dart';
import 'ui/viewmodels/project_detail_controller.dart';
import 'ui/viewmodels/project_settings_controller.dart';

/// Registers the project-detail dependency chain with GetX.
///
/// Debe registrarse antes que la creación de proyectos: el asistente guarda
/// aquí el detalle del proyecto que publica.
void registerProjectDetail() {
  registerProjectApplications();
  Get.put<IProjectDetailSource>(LocalProjectDetailSource());
  Get.put<IProjectDetailRepository>(ProjectDetailRepository(Get.find()));
  Get.put(ProjectDetailController(Get.find()), permanent: true);
  Get.put(ProjectSettingsController(Get.find(), Get.find()), permanent: true);
}
