import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../home/domain/models/project.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';
import '../../domain/models/publication.dart';
import '../../domain/models/viewer_role.dart';
import '../../domain/repositories/i_project_detail_repository.dart';

/// Estado de la pantalla de detalle de un proyecto.
class ProjectDetailController extends GetxController with UiLoggy {
  ProjectDetailController(this._repository);

  final IProjectDetailRepository _repository;

  final Rxn<ProjectDetail> _detail = Rxn<ProjectDetail>();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final RxBool isFollowing = false.obs;
  final RxBool isSaved = false.obs;
  final RxList<Publication> publications = <Publication>[].obs;

  /// Quien está en sesión; se necesita al postularse a un proyecto ajeno.
  final Rxn<ProjectMember> currentUser = Rxn<ProjectMember>();

  ProjectDetail? get detail => _detail.value;

  /// Carga el detalle del proyecto abierto desde el feed.
  ///
  /// Recibe la entidad del feed porque es lo que entregan las tarjetas de
  /// home; si el proyecto todavía no tiene detalle guardado se arma uno
  /// mínimo con lo que el feed ya conoce.
  Future<void> load(Project project) async {
    loggy.debug('ProjectDetailController: loading ${project.id}');
    isLoading.value = true;
    errorMessage.value = null;
    isFollowing.value = false;
    isSaved.value = false;
    publications.clear();
    try {
      final stored = await _repository.getDetail(project.id);
      _detail.value = stored ?? _fromFeedProject(project);
      currentUser.value = await _repository.getCurrentUser();
    } catch (exception) {
      loggy.error('ProjectDetailController: error loading ${project.id}',
          exception);
      _detail.value = null;
      errorMessage.value = 'No se pudo cargar la información del proyecto.';
    } finally {
      isLoading.value = false;
    }
  }

  ProjectDetail _fromFeedProject(Project project) => ProjectDetail(
    projectId: project.id,
    name: project.name,
    coverUrl: project.imageUrl,
    stage: project.stage,
    tags: project.tags,
    description: project.description,
    viewerRole: ViewerRole.visitor,
  );

  /// Refleja en pantalla lo que se acaba de guardar en la configuración.
  void applyUpdate(ProjectDetail updated) => _detail.value = updated;

  void toggleFollowing() => isFollowing.toggle();

  void toggleSaved() => isSaved.toggle();

  void addPublication(Publication publication) => publications.insert(0, publication);

  void updatePublication(Publication publication) {
    final index = publications.indexWhere((item) => item.id == publication.id);
    if (index == -1) return;
    publications[index] = publication;
  }

  void deletePublication(String publicationId) {
    publications.removeWhere((item) => item.id == publicationId);
  }

  void togglePublicationReaction(String publicationId) {
    final index = publications.indexWhere((item) => item.id == publicationId);
    if (index == -1) return;
    final publication = publications[index];
    publications[index] = publication.copyWith(
      viewerReacted: !publication.viewerReacted,
      reactionCount: publication.reactionCount +
          (publication.viewerReacted ? -1 : 1),
    );
  }

  void addPublicationComment(String publicationId, String comment) {
    final index = publications.indexWhere((item) => item.id == publicationId);
    if (index == -1) return;
    final publication = publications[index];
    publications[index] = publication.copyWith(
      commentCount: publication.commentCount + 1,
      comments: [...publication.comments, comment],
    );
  }
}
