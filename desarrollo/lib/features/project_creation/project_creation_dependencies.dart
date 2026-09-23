import 'package:get/get.dart';

import 'data/datasources/i_project_creation_source.dart';
import 'data/datasources/local/local_project_creation_source.dart';
import 'data/datasources/roble_project_creation_source.dart';
import 'data/repositories/project_creation_repository.dart';
import 'domain/repositories/i_project_creation_repository.dart';
import 'ui/viewmodels/project_creation_controller.dart';

/// Registers the project-creation dependency chain with GetX.
///
/// [remote] elige entre ROBLE (producción) y los catálogos en memoria
/// (pruebas offline). `main.dart` no pasa nada y usa ROBLE.
void registerProjectCreation({bool remote = true}) {
  Get.put<IProjectCreationSource>(
    remote ? RobleProjectCreationSource(Get.find()) : LocalProjectCreationSource(),
  );
  Get.put<IProjectCreationRepository>(ProjectCreationRepository(Get.find()));
  Get.put(
    ProjectCreationController(Get.find(), Get.find(), Get.find()),
    permanent: true,
  );
}
