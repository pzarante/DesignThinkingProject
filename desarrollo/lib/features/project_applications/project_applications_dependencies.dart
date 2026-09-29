import 'package:get/get.dart';

import 'data/datasources/i_project_application_source.dart';
import 'data/datasources/local/local_project_application_source.dart';
import 'data/datasources/roble_project_application_source.dart';
import 'data/repositories/project_application_repository.dart';
import 'domain/repositories/i_project_application_repository.dart';
import 'ui/viewmodels/applicants_controller.dart';
import 'ui/viewmodels/apply_controller.dart';

/// [remote] elige entre ROBLE (producción) y las postulaciones en memoria
/// (pruebas offline). `main.dart` no pasa nada y usa ROBLE.
void registerProjectApplications({bool remote = true}) {
  // permanent: las postulaciones deben sobrevivir la navegación y ser
  // visibles desde "Mis aplicaciones" (Persona 4).
  Get.put<IProjectApplicationSource>(
    remote
        ? RobleProjectApplicationSource(Get.find(), Get.find())
        : LocalProjectApplicationSource(),
    permanent: true,
  );
  Get.put<IProjectApplicationRepository>(
    ProjectApplicationRepository(Get.find()),
    permanent: true,
  );
  Get.put(ApplyController(Get.find()), permanent: true);
  Get.put(ApplicantsController(Get.find()), permanent: true);
}
