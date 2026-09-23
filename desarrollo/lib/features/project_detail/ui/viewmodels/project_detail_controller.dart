import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../home/domain/models/project.dart';
import '../../../notifications/domain/models/app_notification.dart';
import '../../../notifications/ui/viewmodels/notifications_controller.dart';
import '../../domain/models/project_comment.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';
import '../../domain/models/project_role.dart';
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
    publications.clear();
    try {
      final stored = await _repository.getDetail(project.id);
      _detail.value = stored ?? _fromFeedProject(project);
      currentUser.value = await _repository.getCurrentUser();

      final likeStatus = await _repository.getLikeStatus(project.id);
      likeCount.value = likeStatus.count;
      likedByMe.value = likeStatus.likedByMe;
      comments.value = await _repository.getComments(project.id);
    } catch (exception) {
      loggy.error(
        'ProjectDetailController: error loading ${project.id}',
        exception,
      );
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
    openRoles: const [],
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

  void addPublication(Publication publication) =>
      publications.insert(0, publication);

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
      reactionCount:
          publication.reactionCount + (publication.viewerReacted ? -1 : 1),
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

  /// Se llama al aceptar una postulación desde la sección de Postulaciones:
  /// ocupa un cupo del rol correspondiente, agrega a quien se postuló como
  /// miembro real del equipo, y notifica. Si el rol ya no existe en
  /// `openRoles` (se editó/borró mientras la postulación esperaba
  /// respuesta), sigue agregando al miembro pero sin descontar cupos.
  Future<void> onApplicationAccepted({
    required String applicantId,
    required String applicantName,
    String? applicantEmail,
    required String roleTitle,
  }) async {
    final current = detail;
    if (current == null) return;

    var updatedRoles = current.openRoles;
    final roleIndex = current.openRoles.indexWhere(
      (role) => role.title == roleTitle,
    );

    if (roleIndex != -1) {
      final role = current.openRoles[roleIndex];
      updatedRoles = List<ProjectRole>.of(current.openRoles);
      updatedRoles[roleIndex] = role.copyWith(
        filledSlots: role.filledSlots + 1,
      );
    }

    // Si ya era miembro (caso raro, pero evita duplicados), no se agrega
    // de nuevo — solo se actualiza su rol.
    final alreadyMember = current.members.any((m) => m.id == applicantId);
    final updatedMembers = alreadyMember
        ? [
            for (final member in current.members)
              member.id == applicantId
                  ? member.copyWith(roleLabel: roleTitle.toUpperCase())
                  : member,
          ]
        : [
            ...current.members,
            ProjectMember(
              id: applicantId,
              name: applicantName,
              email: applicantEmail,
              roleLabel: roleTitle.toUpperCase(),
              subtitle: roleTitle,
            ),
          ];

    final updatedDetail = current.copyWith(
      openRoles: updatedRoles,
      members: updatedMembers,
    );
    await _repository.saveDetail(updatedDetail);
    _detail.value = updatedDetail;

    await Get.find<NotificationsController>().push(
      type: NotificationType.applicationAccepted,
      title: 'Postulación aceptada',
      message:
          '$applicantName ahora es parte de $roleTitle en '
          '${current.name}.',
      projectId: current.projectId,
    );
  }

  /// Se llama al rechazar una postulación.
  Future<void> onApplicationRejected({required String applicantName}) async {
    final current = detail;
    if (current == null) return;

    await Get.find<NotificationsController>().push(
      type: NotificationType.applicationRejected,
      title: 'Postulación rechazada',
      message:
          'La postulación de $applicantName a ${current.name} fue '
          'rechazada.',
      projectId: current.projectId,
    );
  }
}
