import 'package:get/get.dart';

import 'data/datasources/i_home_source.dart';
import 'data/datasources/local/local_home_source.dart';
import 'data/repositories/home_repository.dart';
import 'data/repositories/local_project_application_repository.dart';
import 'domain/repositories/i_home_repository.dart';
import 'domain/repositories/i_project_application_repository.dart';
import 'ui/viewmodels/home_controller.dart';
import 'ui/viewmodels/project_application_controller.dart';

/// Registers the home dependency chain with GetX.
///
/// Swap [LocalHomeSource] for a remote [IHomeSource] implementation here when
/// an API is connected; consumers do not need to change.
void registerHome() {
  Get.put<IHomeSource>(LocalHomeSource());
  Get.put<IHomeRepository>(HomeRepository(Get.find()));
  Get.put<IProjectApplicationRepository>(
    LocalProjectApplicationRepository(),
  );
  Get.put(ProjectApplicationController(Get.find()), permanent: true);
  Get.put(HomeController(Get.find()), permanent: true);
}
