import 'package:get/get.dart';

import '../../../project_applications/domain/models/project_application.dart';
import '../../domain/repositories/i_project_application_repository.dart';

class ProjectApplicationController extends GetxController {
  ProjectApplicationController(this.repository);

  final IProjectApplicationRepository repository;
  final RxList<ProjectApplication> applications = <ProjectApplication>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> loadForProject(String projectId) async {
    isLoading.value = true;
    applications.assignAll(await repository.getForProject(projectId));
    isLoading.value = false;
  }

  Future<void> submit(ProjectApplication application) async {
    final saved = await repository.submit(application);
    applications.add(saved);
  }

  Future<void> updateStatus(
    String applicationId,
    ProjectApplicationStatus status,
  ) async {
    final updated = await repository.updateStatus(applicationId, status);
    final index = applications.indexWhere((item) => item.id == applicationId);
    if (index != -1) applications[index] = updated;
  }
}
