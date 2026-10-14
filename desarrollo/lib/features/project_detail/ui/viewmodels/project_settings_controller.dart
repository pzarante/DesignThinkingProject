import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../../core/error_message.dart';
import '../../../home/domain/repositories/i_home_repository.dart';
import '../../../home/ui/viewmodels/home_controller.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';
import '../../domain/models/project_role.dart';
import '../../domain/models/viewer_role.dart';
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
  final RxList<ProjectRole> openRoles = <ProjectRole>[].obs;
  final RxnString communityName = RxnString();
  final RxnString coverUrl = RxnString();
  final RxBool isSaving = false.obs;

  late ProjectDetail _original;

  /// Quiénes estaban en el equipo al abrir la configuración (o al último
  /// guardado). Es lo que distingue "lo quité yo" de "entró después".
  Set<String> _originalMemberIds = const {};

  /// Detalle resultante del último guardado, para que la pantalla de detalle
  /// se actualice al volver.
  ProjectDetail? saved;

  /// Por qué falló el último guardado, para enseñarlo tal cual.
  String? saveError;

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
    _originalMemberIds = {for (final member in detail.members) member.id};
    nameField.text = detail.name;
    descriptionField.text = detail.description ?? '';
    categoryField.text = detail.tags.isEmpty ? '' : detail.tags.first;
    name.value = detail.name;
    members.value = List.of(detail.members);
    openRoles.value = List.of(detail.openRoles);
    communityName.value = detail.communityName;
    coverUrl.value = detail.coverUrl;
  }

  String get projectId => _original.projectId;

  String get coverName {
    final slug = _original.projectId;
    return coverUrl.value == null ? 'Sin portada' : 'cover_$slug.jpg';
  }

  bool get canSave => name.value.trim().isNotEmpty && !isSaving.value;

  bool get isCreator => _original.viewerRole == ViewerRole.creator;

  void removeCover() {
    coverUrl.value = null;
  }

  /// Primer cupo libre de [role] que nadie del equipo en edición ya tomó: una
  /// fila guardada o, si no queda, uno de los que se crearán al guardar.
  /// Null si el rol está lleno.
  String? freeSlotOf(ProjectRole role) {
    final saved = role.openSlotIds
        .where((id) => !members.any((m) => m.projectRoleId == id))
        .firstOrNull;
    if (saved != null) return saved;
    final pending = members
        .where((m) => m.projectRoleId == role.pendingSlotId)
        .length;
    return pending < role.unsavedSlots ? role.pendingSlotId : null;
  }

  bool _holds(ProjectRole role, String? slotId) =>
      slotId != null && (role.hasSlot(slotId) || slotId == role.pendingSlotId);

  /// Cupos de [role] ocupados en el equipo en edición, contando a quien se
  /// sumó o cambió de rol aunque aún no se haya guardado.
  int filledSlotsOf(ProjectRole role) =>
      members.where((m) => _holds(role, m.projectRoleId)).length;

  /// Roles que se le pueden dar a alguien del equipo: el rol de un integrante
  /// es el cupo que ocupa, así que solo valen los que tienen uno libre.
  List<ProjectRole> get assignableRoles => [
    for (final role in openRoles)
      if (freeSlotOf(role) != null) role,
  ];

  void updateMemberRole(String memberId, ProjectRole role) {
    members.value = [
      for (final member in members)
        if (member.id == memberId && !_holds(role, member.projectRoleId))
          member.copyWith(
            projectRoleId: freeSlotOf(role),
            roleLabel: role.title.toUpperCase(),
            subtitle: role.title,
          )
        else
          member,
    ];
  }

  void addMember(ProjectMember member) {
    if (members.any((m) => m.id == member.id)) return;
    members.add(member);
  }

  void addRole(ProjectRole role) => openRoles.add(role);

  void updateRole(int index, ProjectRole role) {
    // Quien ya tenía un cupo sin guardar lo sigue teniendo tras renombrar.
    final before = openRoles[index].pendingSlotId;
    if (before != role.pendingSlotId) {
      members.value = [
        for (final m in members)
          m.projectRoleId == before
              ? m.copyWith(
                  projectRoleId: role.pendingSlotId,
                  roleLabel: role.title.toUpperCase(),
                  subtitle: role.title,
                )
              : m,
      ];
    }
    final updated = List.of(openRoles);
    updated[index] = role;
    openRoles.value = updated;
  }

  void removeRole(int index) {
    final updated = List.of(openRoles)..removeAt(index);
    openRoles.value = updated;
  }

  /// Quien creó el proyecto no se puede quitar del equipo.
  bool canRemove(ProjectMember member) => !member.isCreator;

  void removeMember(String memberId) =>
      members.removeWhere((member) => member.id == memberId);

  void setCoLeader(String? memberId) {
    members.value = [
      for (final member in members)
        member.copyWith(isCoLeader: memberId != null && member.id == memberId),
    ];
  }

  void unlinkCommunity() => communityName.value = null;

  Future<bool> deleteProject() async {
    isSaving.value = true;
    try {
      await _repository.deleteProject(_original.projectId);
      final homeController = Get.find<HomeController>();
      await homeController.getFeed();
      return true;
    } catch (exception, stackTrace) {
      loggy.error(
        'ProjectSettingsController: delete failed',
        exception,
        stackTrace,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> save() async {
    if (!canSave) return false;
    loggy.debug('ProjectSettingsController: saving ${_original.projectId}');
    isSaving.value = true;
    saveError = null;

    try {
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
        openRoles: List.of(openRoles),
        coverUrl: coverUrl.value,
        communityName: communityName.value,
        clearCommunity: communityName.value == null,
      );

      await _repository.saveDetail(
        updated,
        originalMemberIds: _originalMemberIds,
      );

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
            imageUrl: updated.coverUrl,
          ),
        );
        await homeController.getFeed();
        break;
      }

      saved = updated;
      _original = updated;
      _originalMemberIds = {for (final member in updated.members) member.id};
      return true;
    } catch (exception, stackTrace) {
      loggy.error(
        'ProjectSettingsController: save failed',
        exception,
        stackTrace,
      );
      saveError = errorMessage(exception);
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
