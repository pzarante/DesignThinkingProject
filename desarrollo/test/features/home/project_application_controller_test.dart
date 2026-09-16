import 'package:f_clean_template/features/home/data/repositories/local_project_application_repository.dart';
import 'package:f_clean_template/features/home/domain/models/project_application.dart';
import 'package:f_clean_template/features/home/ui/viewmodels/project_application_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('submitting and resolving an application updates its status', () async {
    final controller = ProjectApplicationController(
      LocalProjectApplicationRepository(),
    );

    await controller.submit(
      const ProjectApplication(
        id: 'application-test',
        projectId: 'r1',
        applicantName: 'Mariana Vergara',
        applicantEmail: 'mariana@uni.edu',
        motivation: 'Quiero aportar al proyecto.',
        availability: '4 horas por semana',
      ),
    );
    await controller.updateStatus(
      'application-test',
      ProjectApplicationStatus.accepted,
    );

    expect(controller.applications.single.status,
        ProjectApplicationStatus.accepted);
  });
}