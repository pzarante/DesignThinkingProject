import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../home/domain/models/community.dart';
import '../../../home/domain/models/project.dart';
import '../../../home/domain/repositories/i_home_repository.dart';
import '../../../home/ui/viewmodels/home_controller.dart';
import '../../domain/models/community_draft.dart';
import '../../domain/repositories/i_community_creation_repository.dart';

/// Estado del formulario de creación de comunidad.
///
/// Igual que el asistente de proyecto, se apoya en [IHomeRepository] para los
/// proyectos del usuario y para guardar la comunidad, porque esas entidades
/// ya viven en la feature home.
class CommunityCreationController extends GetxController with UiLoggy {
  CommunityCreationController(this._repository, this._homeRepository);

  final ICommunityCreationRepository _repository;
  final IHomeRepository _homeRepository;

  final TextEditingController nameField = TextEditingController();
  final TextEditingController descriptionField = TextEditingController();

  final RxString name = ''.obs;
  final RxString description = ''.obs;
  final RxList<String> tags = <String>[].obs;
  final RxList<String> suggestedTags = <String>[].obs;
  final RxnString coverUrl = RxnString();
  final RxnString coverName = RxnString();
  final RxBool isPublic = true.obs;
  final RxBool isSaving = false.obs;

  /// Proyectos del usuario disponibles para vincular.
  final RxList<Project> availableProjects = <Project>[].obs;
  final RxList<String> selectedProjectIds = <String>[].obs;

  @override
  void onInit() {
    _loadSuggestedTags();
    super.onInit();
  }

  @override
  void onClose() {
    nameField.dispose();
    descriptionField.dispose();
    super.onClose();
  }

  Future<void> _loadSuggestedTags() async {
    suggestedTags.value = await _repository.getSuggestedTags();
  }

  /// Deja el formulario en blanco y recarga los proyectos vinculables.
  Future<void> startDraft() async {
    nameField.clear();
    descriptionField.clear();
    name.value = '';
    description.value = '';
    tags.clear();
    selectedProjectIds.clear();
    coverUrl.value = null;
    coverName.value = null;
    isPublic.value = true;
    await loadProjects();
  }

  Future<void> loadProjects() async {
    final feed = await _homeRepository.getFeed();
    availableProjects.value = feed.myProjects;
  }

  void addTag(String tag) => tags.add(tag);

  void removeTag(String tag) => tags.remove(tag);

  void setPublic(bool value) => isPublic.value = value;

  /// Selector de archivos pendiente: sin backend ni plugin de imágenes se
  /// asigna una portada de ejemplo.
  void pickPlaceholderCover() {
    final slug = name.value.trim().isEmpty
        ? 'comunidad'
        : name.value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    coverUrl.value = 'https://picsum.photos/seed/$slug/400/225';
    coverName.value = 'portada_$slug.png';
  }

  void removeCover() {
    coverUrl.value = null;
    coverName.value = null;
  }

  void toggleProject(String projectId) {
    if (selectedProjectIds.contains(projectId)) {
      selectedProjectIds.remove(projectId);
      return;
    }
    selectedProjectIds.add(projectId);
  }

  void removeProject(String projectId) => selectedProjectIds.remove(projectId);

  /// Vincula un proyecto recién creado desde el asistente y lo suma a la
  /// lista de vinculables sin esperar a recargar el feed entero.
  void linkCreatedProject(Project project) {
    if (!availableProjects.any((p) => p.id == project.id)) {
      availableProjects.insert(0, project);
    }
    if (!selectedProjectIds.contains(project.id)) {
      selectedProjectIds.add(project.id);
    }
  }

  List<Project> get selectedProjects => availableProjects
      .where((project) => selectedProjectIds.contains(project.id))
      .toList();

  /// El diseño exige nombre y al menos un proyecto vinculado.
  bool get canSubmit =>
      name.value.trim().isNotEmpty && selectedProjectIds.isNotEmpty;

  CommunityDraft get draft => CommunityDraft(
    name: name.value.trim(),
    description: description.value.trim(),
    tags: List.unmodifiable(tags),
    coverUrl: coverUrl.value,
    isPublic: isPublic.value,
    projectIds: List.unmodifiable(selectedProjectIds),
  );

  Future<Community> create() async {
    loggy.debug('CommunityCreationController: creating ${name.value}');
    isSaving.value = true;

    final community = Community(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      name: name.value.trim(),
      description: description.value.trim().isEmpty
          ? null
          : description.value.trim(),
      tags: List.unmodifiable(tags),
      coverUrl: coverUrl.value,
      isPublic: isPublic.value,
      projectIds: List.unmodifiable(selectedProjectIds),
      lastActivity: 'Sin actividad reciente',
    );

    await _homeRepository.addCommunity(community);
    // El feed del home es permanente y no se reconstruye solo al volver.
    await Get.find<HomeController>().getFeed();

    isSaving.value = false;
    return community;
  }
}
