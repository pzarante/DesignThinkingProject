import 'package:f_clean_template/features/project_applications/data/repositories/local_project_application_repository.dart';
import 'package:f_clean_template/features/project_applications/domain/models/project_application.dart';
import 'package:f_clean_template/features/project_applications/ui/viewmodels/applicants_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepting an application updates its status', () async {
    final repository = LocalProjectApplicationRepository();
    final controller = ApplicantsController(repository);

    await repository.submit(
      ProjectApplication(
        id: 'application-test',
        projectId: 'r1',
        applicantId: 'u-test',
        applicantName: 'Mariana Vergara',
        applicantEmail: 'mariana@uni.edu',
        motivation: 'Quiero aportar al proyecto.',
        availability: '4 horas por semana',
        createdAt: DateTime.now(),
      ),
    );

    await controller.load('r1');
    expect(
      controller.applications.single.status,
      ProjectApplicationStatus.pending,
    );

    await controller.accept(controller.applications.single);
    expect(
      controller.applications.single.status,
      ProjectApplicationStatus.accepted,
    );
  });
}
