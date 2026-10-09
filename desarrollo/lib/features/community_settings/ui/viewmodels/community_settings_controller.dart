import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import '../../../../core/widgets/app_snackbar.dart';

import '../../../home/domain/models/community.dart';
import '../../../home/domain/models/project.dart';
import '../../../home/domain/repositories/i_home_repository.dart';
import '../../../home/ui/viewmodels/home_controller.dart';

/// Estado de la configuración de una comunidad.
class CommunitySettingsController extends GetxController with UiLoggy {
  CommunitySettingsController(this._homeRepository);

  final IHomeRepository _homeRepository;

  final TextEditingController nameField = TextEditingController();
  final TextEditingController descriptionField = TextEditingController();

  final RxString name = ''.obs;
  final RxString description = ''.obs;
  final RxList<String> tags = <String>[].obs;
  final RxList<String> suggestedTags = <String>[].obs;
  final RxList<Project> availableProjects = <Project>[].obs;
  final RxList<String> selectedProjectIds = <String>[].obs;
  final RxnString coverUrl = RxnString();
  final RxnString coverName = RxnString();
  final RxBool isPublic = true.obs;
  final RxBool isSaving = false.obs;

  late Community _original;
  Community? saved;

  @override
  void onClose() {
    nameField.dispose();
    descriptionField.dispose();
    super.onClose();
  }

  Future<void> start(Community community) async {
    _original = community;
    nameField.text = community.name;
    descriptionField.text = community.description ?? '';
    name.value = community.name;
    description.value = community.description ?? '';
    tags.value = List.of(community.tags);
    coverUrl.value = community.coverUrl;
    coverName.value = community.coverUrl == null ? null : 'cover_${community.id}.jpg';
    isPublic.value = community.isPublic;
    selectedProjectIds.value = List.of(community.projectIds);

    final feed = await _homeRepository.getFeed();
    availableProjects.value = List.of(feed.myProjects);
    final allTags = <String>{
      ...community.tags,
      ...feed.myProjects.expand((project) => project.tags),
      ...feed.followedCommunities.expand((communityItem) => communityItem.tags),
    }.toList();
    suggestedTags.value = allTags..sort();
  }

  bool get canSave => name.value.trim().isNotEmpty;

  void addTag(String tag) {
    final value = tag.trim();
    if (value.isEmpty || tags.contains(value)) return;
    tags.add(value);
  }

  void removeTag(String tag) => tags.remove(tag);

  void toggleProject(String projectId) {
    if (selectedProjectIds.contains(projectId)) {
      selectedProjectIds.remove(projectId);
      return;
    }
    selectedProjectIds.add(projectId);
  }

  void changeCover() {
    final slug = name.value.trim().isEmpty
        ? 'comunidad'
        : name.value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    coverUrl.value = 'https://picsum.photos/seed/$slug/400/225';
    coverName.value = 'cover_$slug.jpg';
  }

  void removeCover() {
    coverUrl.value = null;
    coverName.value = null;
  }

  Future<bool> save() async {
    isSaving.value = true;
    try {
      final updated = _original.copyWith(
        name: nameField.text.trim(),
        description: descriptionField.text.trim().isEmpty
            ? null
            : descriptionField.text.trim(),
        tags: List.unmodifiable(tags),
        coverUrl: coverUrl.value,
        isPublic: isPublic.value,
        projectIds: List.unmodifiable(selectedProjectIds),
        lastActivity: 'Configuración actualizada',
      );

      await _homeRepository.updateCommunity(updated);
      await Get.find<HomeController>().getFeed();
      saved = updated;
      _original = updated;
      showSuccessSnack(
        'Cambios guardados',
        message: 'La comunidad se actualizó correctamente.',
      );
      return true;
    } catch (exception, stackTrace) {
      loggy.error('CommunitySettingsController: save failed', exception, stackTrace);
      showErrorSnack(
        'No se pudo guardar',
        message: 'Revisa los datos e inténtalo de nuevo.',
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
