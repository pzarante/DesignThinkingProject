import 'package:f_clean_template/features/home/home_dependencies.dart';
import 'package:f_clean_template/features/project_applications/domain/models/project_application.dart';
import 'package:f_clean_template/features/project_applications/domain/repositories/i_project_application_repository.dart';
import 'package:f_clean_template/features/project_applications/ui/viewmodels/applicants_controller.dart';
import 'package:f_clean_template/features/project_detail/domain/repositories/i_project_detail_repository.dart';
import 'package:f_clean_template/features/project_detail/project_detail_dependencies.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    registerFakeAuth();
    registerHome(remote: false);
    registerProjectDetail(remote: false);
  });

  tearDown(Get.reset);

  test('accepting an application updates its status and joins the team', () async {
    final repository = Get.find<IProjectApplicationRepository>();
    final controller = Get.find<ApplicantsController>();

    await repository.submit(
      ProjectApplication(
        id: 'application-test',
        projectId: 'p1',
        projectRoleId: 'Diseñador UX',
        roleTitle: 'Diseñador UX',
        applicantId: 'u-test',
        applicantName: 'Mariana Vergara',
        applicantEmail: 'mariana@uni.edu',
        motivation: 'Quiero aportar al proyecto.',
        availability: '4 horas por semana',
        createdAt: DateTime.now(),
      ),
    );

    await controller.load('p1');
    final mine = controller.applications.singleWhere(
      (a) => a.id == 'application-test',
    );
    expect(mine.status, ProjectApplicationStatus.pending);

    expect(await controller.accept(mine), isNull);
    expect(
      controller.applications
          .singleWhere((a) => a.id == 'application-test')
          .status,
      ProjectApplicationStatus.accepted,
    );

    final detail = await Get.find<IProjectDetailRepository>().getDetail('p1');
    expect(detail!.members.map((m) => m.id), contains('u-test'));
  });

  test('a rejected application no longer counts as pending', () async {
    final repository = Get.find<IProjectApplicationRepository>();
    final controller = Get.find<ApplicantsController>();

    await controller.load('p1');
    final application = controller.applications.first;
    expect(
      await repository.hasApplied(
        projectId: 'p1',
        applicantId: application.applicantId,
      ),
      isTrue,
    );

    expect(await controller.reject(application), isNull);
    expect(
      await repository.hasApplied(
        projectId: 'p1',
        applicantId: application.applicantId,
      ),
      isFalse,
    );
  });
}
