import 'package:f_clean_template/features/project_applications/data/repositories/local_project_application_repository.dart';
import 'package:f_clean_template/features/project_applications/domain/models/project_application.dart';
import 'package:f_clean_template/features/project_applications/ui/viewmodels/applicants_controller.dart';
import 'package:f_clean_template/features/home/home_dependencies.dart';
import 'package:f_clean_template/features/notifications/notifications_dependencies.dart';
import 'package:f_clean_template/features/project_detail/project_detail_dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  setUp(() {
    // Aceptar una postulación toca el detalle del proyecto (ocupa un cupo del
    // rol y suma al equipo) y deja una notificación: los dos controladores
    // tienen que existir.
    Get.testMode = true;
    registerFakeAuth();
    registerNotifications();
    registerHome(remote: false);
    registerProjectDetail(remote: false);
  });

  tearDown(Get.reset);

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
