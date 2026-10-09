import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../../core/error_message.dart' as errors;
import '../../../home/domain/models/project.dart';
import '../../../home/ui/viewmodels/home_controller.dart';
import '../../../notifications/domain/models/app_notification.dart';
import '../../../notifications/ui/viewmodels/notifications_controller.dart';
import '../../domain/models/project_comment.dart';
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
      // Todo a la vez: son consultas independientes y encadenarlas era
      // sumar una espera de red detrás de otra.
      final [stored, user, likeStatus, loadedComments, flags] =
          await Future.wait<Object?>([
            _repository.getDetail(project.id),
            _repository.getCurrentUser(),
            _repository.getLikeStatus(project.id),
            _repository.getComments(project.id),
            _repository.getViewerFlags(project.id),
          ]);

      _detail.value = (stored as ProjectDetail?) ?? _fromFeedProject(project);
      currentUser.value = user as ProjectMember;
      final likes = likeStatus as ({int count, bool likedByMe});
      likeCount.value = likes.count;
      likedByMe.value = likes.likedByMe;
      comments.value = loadedComments as List<ProjectComment>;
      final viewerFlags = flags as ({bool saved, bool following});
      isSaved.value = viewerFlags.saved;
      isFollowing.value = viewerFlags.following;
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

  /// Mensaje del último intento de guardar o seguir que no se pudo hacer;
  /// la pantalla lo enseña y lo vacía.
  final RxString actionError = ''.obs;

  Future<void> toggleFollowing() => _toggleFlag(
    flag: isFollowing,
    action: _repository.toggleFollowing,
  );

  Future<void> toggleSaved() =>
      _toggleFlag(flag: isSaved, action: _repository.toggleSaved);

  /// Cambia la marca en pantalla y la escribe; si el servidor la rechaza
  /// —por ejemplo porque hace falta una cuenta— se deshace y se explica.
  Future<void> _toggleFlag({
    required RxBool flag,
    required Future<bool> Function(String projectId) action,
  }) async {
    final projectId = detail?.projectId;
    if (projectId == null) return;

    final previous = flag.value;
    flag.value = !previous;
    actionError.value = '';
    try {
      flag.value = await action(projectId);
    } catch (exception) {
      loggy.error('ProjectDetailController: error toggling flag', exception);
      flag.value = previous;
      actionError.value = errors.errorMessage(exception);
    }
  }

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

  /// Se llama al aceptar una postulación: quien se postuló entra al equipo
  /// ocupando un cupo del rol, y se notifica. Si el rol ya no existe (se
  /// borró mientras la postulación esperaba respuesta), entra igual pero
  /// sin descontar cupos.
  ///
  /// Lanza si no se pudo sumar al equipo.
  Future<void> onApplicationAccepted({
    required String projectId,
    required String projectRoleId,
    required String applicantId,
    required String applicantName,
    String? applicantEmail,
    required String roleTitle,
  }) async {
    await _repository.addMember(
      projectId: projectId,
      member: ProjectMember(
        id: applicantId,
        name: applicantName,
        email: applicantEmail,
      ),
      projectRoleId: projectRoleId,
    );
    if (detail?.projectId == projectId) {
      final fresh = await _repository.getDetail(projectId);
      if (fresh != null) _detail.value = fresh;
    }

    await _push(
      type: NotificationType.applicationAccepted,
      title: 'Postulación aceptada',
      message:
          '$applicantName ahora es parte de $roleTitle en '
          '${_projectName(projectId)}.',
      projectId: projectId,
    );
  }

  /// Se llama al rechazar una postulación.
  Future<void> onApplicationRejected({
    required String projectId,
    required String applicantName,
  }) async {
    await _push(
      type: NotificationType.applicationRejected,
      title: 'Postulación rechazada',
      message:
          'La postulación de $applicantName a ${_projectName(projectId)} '
          'fue rechazada.',
      projectId: projectId,
    );
  }

  /// Mientras se procesa la salida del proyecto abierto.
  final RxBool isLeaving = false.obs;

  /// Integrantes activos del proyecto abierto, sin quien tiene la sesión:
  /// entre ellos se elige al nuevo líder.
  List<ProjectMember> get otherMembers {
    final me = currentUser.value?.id;
    return (detail?.members ?? const <ProjectMember>[])
        .where((m) => m.isActive && m.id != me)
        .toList();
  }

  /// True si quien tiene la sesión lidera el proyecto abierto: para salir
  /// tiene que dejar a alguien a cargo.
  bool get isLeader {
    final me = currentUser.value?.id;
    final mine = detail?.members.where((m) => m.id == me).firstOrNull;
    return mine?.isCreator ?? detail?.viewerRole == ViewerRole.creator;
  }

  /// Sale del equipo del proyecto abierto. Si lidera, [newLeader] es quien
  /// queda a cargo. Avisa al equipo y refresca "Mis Proyectos".
  ///
  /// Devuelve null si salió bien, o el mensaje de error para mostrar.
  Future<String?> leaveProject({ProjectMember? newLeader}) async {
    final current = detail;
    if (current == null) return 'No se encontró el proyecto.';

    isLeaving.value = true;
    try {
      await _repository.leaveProject(
        projectId: current.projectId,
        newLeaderId: newLeader?.id,
      );
    } catch (exception) {
      loggy.error('ProjectDetailController: error leaving', exception);
      isLeaving.value = false;
      return exception is StateError
          ? exception.message
          : errors.errorMessage(exception);
    }

    final whoLeft = currentUser.value?.name;
    await _push(
      type: NotificationType.memberLeft,
      title: 'Un integrante salió del proyecto',
      message: [
        '${whoLeft == null || whoLeft.isEmpty ? 'Un integrante' : whoLeft} '
            'salió de ${current.name}.',
        if (newLeader != null) '${newLeader.name} ahora lo lidera.',
      ].join(' '),
      projectId: current.projectId,
    );

    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().getFeed();
    }
    isLeaving.value = false;
    return null;
  }

  /// Avisa sin arriesgar la operación que lo provocó: aceptar o rechazar
  /// ya ocurrió, y un aviso que no llega no debe mostrarse como si eso
  /// hubiera fallado.
  Future<void> _push({
    required NotificationType type,
    required String title,
    required String message,
    String? projectId,
  }) async {
    if (!Get.isRegistered<NotificationsController>()) return;
    try {
      await Get.find<NotificationsController>().push(
        type: type,
        title: title,
        message: message,
        projectId: projectId,
      );
    } catch (exception) {
      loggy.error('ProjectDetailController: could not notify', exception);
    }
  }

  String _projectName(String projectId) =>
      detail?.projectId == projectId ? detail!.name : 'el proyecto';
}
