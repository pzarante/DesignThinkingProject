import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../home/domain/models/project.dart';
import '../../domain/models/project_comment.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';
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

  final RxInt likeCount = 0.obs;
  final RxBool likedByMe = false.obs;
  final RxList<ProjectComment> comments = <ProjectComment>[].obs;
  final RxBool isSendingComment = false.obs;

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
    try {
      final stored = await _repository.getDetail(project.id);
      _detail.value = stored ?? _fromFeedProject(project);
      currentUser.value = await _repository.getCurrentUser();

      final likeStatus = await _repository.getLikeStatus(project.id);
      likeCount.value = likeStatus.count;
      likedByMe.value = likeStatus.likedByMe;
      comments.value = await _repository.getComments(project.id);
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

  /// Alterna el "me gusta" del proyecto abierto, optimista y con reversa si
  /// el servidor lo rechaza.
  Future<void> toggleLike() async {
    final projectId = detail?.projectId;
    if (projectId == null) return;

    final wasLiked = likedByMe.value;
    likedByMe.value = !wasLiked;
    likeCount.value += wasLiked ? -1 : 1;
    try {
      likeCount.value = await _repository.toggleLike(projectId);
    } catch (exception) {
      loggy.error('ProjectDetailController: error toggling like', exception);
      likedByMe.value = wasLiked;
      likeCount.value += wasLiked ? 1 : -1;
    }
  }

  Future<void> submitComment(String content) async {
    final projectId = detail?.projectId;
    final text = content.trim();
    if (projectId == null || text.isEmpty) return;

    isSendingComment.value = true;
    try {
      comments.add(await _repository.addComment(projectId, text));
    } catch (exception) {
      loggy.error('ProjectDetailController: error posting comment', exception);
    } finally {
      isSendingComment.value = false;
    }
  }
}
