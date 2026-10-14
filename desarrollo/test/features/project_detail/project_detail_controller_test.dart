import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/features/home/domain/models/project.dart';
import 'package:f_clean_template/features/project_detail/domain/models/project_comment.dart';
import 'package:f_clean_template/features/project_detail/domain/models/project_detail.dart';
import 'package:f_clean_template/features/project_detail/domain/models/project_member.dart';
import 'package:f_clean_template/features/project_detail/domain/project_unavailable_exception.dart';
import 'package:f_clean_template/features/project_detail/domain/repositories/i_project_detail_repository.dart';
import 'package:f_clean_template/features/project_detail/ui/viewmodels/project_detail_controller.dart';

/// Repositorio cuyo `getDetail` hace lo que se le diga.
class _Repository implements IProjectDetailRepository {
  _Repository(this.onGetDetail);

  final Future<ProjectDetail?> Function(String projectId) onGetDetail;

  @override
  Future<ProjectDetail?> getDetail(String projectId) => onGetDetail(projectId);

  @override
  Future<ProjectMember> getCurrentUser() async =>
      const ProjectMember(id: 'me', name: 'Yo');

  @override
  Future<({int count, bool likedByMe})> getLikeStatus(String projectId) async =>
      (count: 3, likedByMe: true);

  @override
  Future<List<ProjectComment>> getComments(String projectId) async => const [];

  @override
  Future<({bool saved, bool following})> getViewerFlags(
    String projectId,
  ) async => (saved: true, following: true);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _fromFeed = Project(id: 'p1', name: 'Nombre viejo del feed');

void main() {
  tearDown(Get.reset);

  test('un proyecto disponible muestra su detalle guardado', () async {
    final controller = ProjectDetailController(
      _Repository(
        (_) async => const ProjectDetail(projectId: 'p1', name: 'Guardado'),
      ),
    );

    await controller.load(_fromFeed);

    expect(controller.detail?.name, 'Guardado');
    expect(controller.errorMessage.value, isNull);
    expect(controller.isUnavailable.value, isFalse);
  });

  test(
    'sin detalle guardado pero disponible, se arma uno con lo del feed',
    () async {
      final controller = ProjectDetailController(
        _Repository((_) async => null),
      );

      await controller.load(_fromFeed);

      expect(controller.detail?.name, 'Nombre viejo del feed');
      expect(controller.errorMessage.value, isNull);
    },
  );

  test('un proyecto borrado no cae en el respaldo del feed', () async {
    final controller = ProjectDetailController(
      _Repository((_) async => throw const ProjectUnavailableException()),
    );

    await controller.load(_fromFeed);

    expect(controller.detail, isNull);
    expect(controller.isUnavailable.value, isTrue);
    expect(
      controller.errorMessage.value,
      'Este proyecto ya no está disponible.',
    );
    expect(controller.isLoading.value, isFalse);
  });

  test('al borrarse se limpia lo del proyecto que se estaba viendo', () async {
    var deleted = false;
    final controller = ProjectDetailController(
      _Repository(
        (_) async => deleted
            ? throw const ProjectUnavailableException()
            : const ProjectDetail(projectId: 'p1', name: 'Guardado'),
      ),
    );
    await controller.load(_fromFeed);
    expect(controller.likeCount.value, 3);
    expect(controller.isFollowing.value, isTrue);

    deleted = true;
    await controller.load(_fromFeed);

    expect(controller.detail, isNull);
    expect(controller.likeCount.value, 0);
    expect(controller.likedByMe.value, isFalse);
    expect(controller.isSaved.value, isFalse);
    expect(controller.isFollowing.value, isFalse);
    expect(controller.comments, isEmpty);
  });

  test(
    'un fallo de red sigue siendo un error que se puede reintentar',
    () async {
      final controller = ProjectDetailController(
        _Repository((_) async => throw Exception('sin red')),
      );

      await controller.load(_fromFeed);

      expect(controller.detail, isNull);
      expect(controller.isUnavailable.value, isFalse);
      expect(
        controller.errorMessage.value,
        'No se pudo cargar la información del proyecto.',
      );
    },
  );

  test('recargar después de un borrado reinicia la marca', () async {
    var deleted = true;
    final controller = ProjectDetailController(
      _Repository(
        (_) async => deleted
            ? throw const ProjectUnavailableException()
            : const ProjectDetail(projectId: 'p1', name: 'Guardado'),
      ),
    );
    await controller.load(_fromFeed);
    expect(controller.isUnavailable.value, isTrue);

    deleted = false;
    await controller.load(_fromFeed);

    expect(controller.isUnavailable.value, isFalse);
    expect(controller.detail?.name, 'Guardado');
  });
}
