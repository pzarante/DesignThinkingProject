import 'package:get/get.dart';

import '../../domain/models/project_application.dart';
import '../../domain/repositories/i_project_application_repository.dart';

class ApplicantsController extends GetxController {
  ApplicantsController(this.repository);

  final IProjectApplicationRepository repository;
  final RxList<ProjectApplication> applications = <ProjectApplication>[].obs;
  final RxBool isLoading = false.obs;

  List<ProjectApplication> get pending => applications
      .where((a) => a.status == ProjectApplicationStatus.pending)
      .toList();

  Future<void> load(String projectId) async {
    isLoading.value = true;
    applications.assignAll(await repository.getForProject(projectId));
    isLoading.value = false;
  }

  Future<void> accept(ProjectApplication application) async {
    await repository.updateStatus(
      application.id,
      ProjectApplicationStatus.accepted,
    );
    await load(application.projectId);
  }

  Future<void> reject(ProjectApplication application) async {
    await repository.updateStatus(
      application.id,
      ProjectApplicationStatus.rejected,
    );
    await load(application.projectId);
  }
}
