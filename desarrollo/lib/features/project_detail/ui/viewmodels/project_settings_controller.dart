import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../home/domain/repositories/i_home_repository.dart';
import '../../../home/ui/viewmodels/home_controller.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';
import '../../domain/repositories/i_project_detail_repository.dart';

/// Estado de la configuración de un proyecto: edita una copia de trabajo y
/// solo la aplica al pulsar "Guardar cambios".
///
/// Además del repositorio propio usa [IHomeRepository] para que el nombre y
/// la descripción editados se vean también en las tarjetas del feed.
class ProjectSettingsController extends GetxController with UiLoggy {
  ProjectSettingsController(this._repository, this._homeRepository);

  final IProjectDetailRepository _repository;
  final IHomeRepository _homeRepository;

  final TextEditingController nameField = TextEditingController();
  final TextEditingController descriptionField = TextEditingController();
  final TextEditingController categoryField = TextEditingController();

  final RxString name = ''.obs;
  final RxList<ProjectMember> members = <ProjectMember>[].obs;
  final RxnString communityName = RxnString();
  final RxnString coverUrl = RxnString();
  final RxBool isSaving = false.obs;

  late ProjectDetail _original;

  /// Detalle resultante del último guardado, para que la pantalla de detalle
  /// se actualice al volver.
  ProjectDetail? saved;

  @override
  void onClose() {
    nameField.dispose();
    descriptionField.dispose();
    categoryField.dispose();
    super.onClose();
  }

  /// Carga la copia de trabajo a partir del detalle que se está viendo.
  void start(ProjectDetail detail) {
    _original = detail;
    nameField.text = detail.name;
    descriptionField.text = detail.description ?? '';
    categoryField.text = detail.tags.isEmpty ? '' : detail.tags.first;
    name.value = detail.name;
    members.value = List.of(detail.members);
    communityName.value = detail.communityName;
    coverUrl.value = detail.coverUrl;
  }

  String get projectId => _original.projectId;

  String get coverName {
    final slug = _original.projectId;
    return coverUrl.value == null ? 'Sin portada' : 'cover_$slug.jpg';
  }

  /// Selector de archivos pendiente: se rota a otra portada de ejemplo.
  void changeCover() {
    coverUrl.value =
        'https://picsum.photos/seed/${_original.projectId}'
        '${DateTime.now().second}/400/225';
  }

  void updateMemberRole(String memberId, String roleLabel) {
    members.value = [
      for (final member in members)
        member.id == memberId ? member.copyWith(roleLabel: roleLabel) : member,
    ];
  }

  /// Quien creó el proyecto no se puede quitar del equipo.
  bool canRemove(ProjectMember member) => !member.isCreator;

  void removeMember(String memberId) =>
      members.removeWhere((member) => member.id == memberId);

  void setCoLeader(String memberId) {
    members.value = [
      for (final member in members)
        member.copyWith(isCoLeader: member.id == memberId),
    ];
  }

  void unlinkCommunity() => communityName.value = null;

  Future<void> save() async {
    loggy.debug('ProjectSettingsController: saving ${_original.projectId}');
    isSaving.value = true;

    final category = categoryField.text.trim();
    final tags = <String>[
      if (category.isNotEmpty) category,
      ..._original.tags.skip(1),
    ];
    final description = descriptionField.text.trim();

    final updated = _original.copyWith(
      name: nameField.text.trim(),
      description: description,
      tags: tags,
      members: List.of(members),
      coverUrl: coverUrl.value,
      communityName: communityName.value,
      clearCommunity: communityName.value == null,
    );

    await _repository.saveDetail(updated);

    // El feed guarda su propia versión resumida del proyecto: se sincroniza
    // lo que ambas pantallas comparten.
    final homeController = Get.find<HomeController>();
    for (final project in [
      ...homeController.feed.myProjects,
      ...homeController.feed.recommendedProjects,
    ]) {
      if (project.id != updated.projectId) continue;
      await _homeRepository.updateProject(
        project.copyWith(
          name: updated.name,
          description: description.isEmpty ? null : description,
          tags: tags,
        ),
      );
      await homeController.getFeed();
      break;
    }

    saved = updated;
    _original = updated;
    isSaving.value = false;
  }
}
