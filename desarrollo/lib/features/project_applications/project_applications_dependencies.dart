import 'package:get/get.dart';

import 'data/repositories/local_project_application_repository.dart';
import 'domain/repositories/i_project_application_repository.dart';
import 'ui/viewmodels/applicants_controller.dart';
import 'ui/viewmodels/apply_controller.dart';

void registerProjectApplications() {
  // permanent: las postulaciones deben sobrevivir la navegación y ser
  // visibles desde "Mis aplicaciones" (Persona 4).
  Get.put<IProjectApplicationRepository>(
    LocalProjectApplicationRepository(),
    permanent: true,
  );
  Get.put(ApplyController(Get.find()), permanent: true);
  Get.put(ApplicantsController(Get.find()), permanent: true);
}
