import 'package:flutter_test/flutter_test.dart';

import 'package:f_clean_template/features/home/domain/repositories/i_home_repository.dart';
import 'package:f_clean_template/features/project_detail/domain/models/project_detail.dart';
import 'package:f_clean_template/features/project_detail/domain/models/project_member.dart';
import 'package:f_clean_template/features/project_detail/domain/models/project_role.dart';
import 'package:f_clean_template/features/project_detail/domain/repositories/i_project_detail_repository.dart';
import 'package:f_clean_template/features/project_detail/ui/viewmodels/project_settings_controller.dart';

// Los cupos se calculan en memoria: los repositorios no se llegan a usar.
class _Unused implements IProjectDetailRepository, IHomeRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  const owner = ProjectMember(id: 'owner', name: 'owner', isCreator: true);
  const dev = ProjectRole(
    title: 'Dev',
    totalSlots: 1,
    filledSlots: 1,
    slotIds: ['slot-1'],
  );

  ProjectSettingsController fullTeam() =>
      ProjectSettingsController(_Unused(), _Unused())..start(
        const ProjectDetail(
          projectId: 'p1',
          name: 'MotionLab',
          creator: owner,
          members: [
            owner,
            ProjectMember(id: 'ana', name: 'ana', projectRoleId: 'slot-1'),
          ],
          openRoles: [dev],
        ),
      );

  test('con todos los cupos ocupados no se puede sumar a nadie', () {
    expect(fullTeam().assignableRoles, isEmpty);
  });

  test('una vacante nueva vuelve a dejar sumar, hasta llenar sus cupos', () {
    final controller = fullTeam()
      ..addRole(const ProjectRole(title: 'UX', totalSlots: 2));
    final ux = controller.openRoles.last;

    for (final id in ['luis', 'eva']) {
      final slot = controller.freeSlotOf(ux);
      expect(slot, ux.pendingSlotId);
      controller.addMember(
        ProjectMember(id: id, name: id, projectRoleId: slot),
      );
    }

    expect(controller.freeSlotOf(ux), isNull);
    expect(controller.filledSlotsOf(ux), 2);
    expect(controller.assignableRoles, isEmpty);
  });

  test('subir los cupos de un rol lleno lo vuelve a abrir', () {
    final controller = fullTeam()..updateRole(0, dev.copyWith(totalSlots: 2));

    expect(controller.freeSlotOf(controller.openRoles.single), 'pendiente:Dev');
  });

  test('renombrar el rol conserva el cupo sin guardar de quien lo tiene', () {
    final controller = fullTeam()..addRole(const ProjectRole(title: 'UX'));
    controller.addMember(
      ProjectMember(
        id: 'luis',
        name: 'luis',
        projectRoleId: controller.openRoles.last.pendingSlotId,
      ),
    );

    controller.updateRole(1, const ProjectRole(title: 'Diseño UX'));

    expect(controller.filledSlotsOf(controller.openRoles.last), 1);
  });
}
