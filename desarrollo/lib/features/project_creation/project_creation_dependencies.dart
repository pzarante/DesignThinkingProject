import 'package:get/get.dart';

import 'data/datasources/i_project_creation_source.dart';
import 'data/datasources/local/local_project_creation_source.dart';
import 'data/repositories/project_creation_repository.dart';
import 'domain/repositories/i_project_creation_repository.dart';
import 'ui/viewmodels/project_creation_controller.dart';

/// Registers the project-creation dependency chain with GetX.
///
/// Cambiar [LocalProjectCreationSource] por una implementación remota de
/// [IProjectCreationSource] aquí no obliga a tocar nada por encima.
void registerProjectCreation() {
  Get.put<IProjectCreationSource>(LocalProjectCreationSource());
  Get.put<IProjectCreationRepository>(ProjectCreationRepository(Get.find()));
  Get.put(
    ProjectCreationController(Get.find(), Get.find(), Get.find()),
    permanent: true,
  );
}
