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
import '../../domain/project_unavailable_exception.dart';
import '../../domain/repositories/i_project_detail_repository.dart';

/// Estado de la pantalla de detalle de un proyecto.
class ProjectDetailController extends GetxController with UiLoggy {
  ProjectDetailController(this._repository);

  final IProjectDetailRepository _repository;

  final Rxn<ProjectDetail> _detail = Rxn<ProjectDetail>();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  /// El proyecto se borró: reintentar no sirve y no hay detalle que mostrar.
  final RxBool isUnavailable = false.obs;
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

  /// Lo que la tarjeta del feed ya sabe del proyecto, para pintar la cabecera
  /// mientras llega el detalle completo.
  final Rxn<ProjectDetail> preview = Rxn<ProjectDetail>();

  /// Carga el detalle del proyecto abierto desde el feed.
  ///
  /// Recibe la entidad del feed porque es lo que entregan las tarjetas de
  /// home; si el proyecto todavía no tiene detalle guardado se arma uno
  /// mínimo con lo que el feed ya conoce.
  Future<void> load(Project project) async {
    loggy.debug('ProjectDetailController: loading ${project.id}');
    preview.value = _fromFeedProject(project);
    isLoading.value = true;
    errorMessage.value = null;
    isUnavailable.value = false;
    isFollowing.value = false;
    isSaved.value = false;
    publications.clear();
    try {
      // Todo a la vez: son consultas independientes y encadenarlas era
      // sumar una espera de red detrás de otra.
      final [
        stored,
        user,
        likeStatus,
        loadedComments,
        flags,
        loadedPublications,
      ] = await Future.wait<Object?>([
        _repository.getDetail(project.id),
        _repository.getCurrentUser(),
        _repository.getLikeStatus(project.id),
        _repository.getComments(project.id),
        _repository.getViewerFlags(project.id),
        // Un muro que no carga no debe tumbar el resto del proyecto.
        _repository.getPublications(project.id).catchError((Object e) {
          loggy.error('ProjectDetailController: publications', e);
          actionError.value = 'No se pudieron cargar las publicaciones.';
          return <Publication>[];
        }),
      ]);

      _detail.value = (stored as ProjectDetail?) ?? _fromFeedProject(project);
      currentUser.value = user as ProjectMember;
      final likes = likeStatus as ({int count, bool likedByMe});
      likeCount.value = likes.count;
      likedByMe.value = likes.likedByMe;
      // Copia modificable: la fuente devuelve `const []` cuando no hay
      // comentarios y luego se le añaden (y se le hace `clear`).
      comments.value = List.of(loadedComments as List<ProjectComment>);
      final viewerFlags = flags as ({bool saved, bool following});
      isSaved.value = viewerFlags.saved;
      isFollowing.value = viewerFlags.following;
      publications.value = List.of(loadedPublications as List<Publication>);
    } on ProjectUnavailableException catch (exception) {
      // Sin el respaldo del feed: lo que traía la tarjeta es justo lo que ya
      // no vale. Se vacía todo lo del proyecto anterior y se refresca el
      // feed para que la tarjeta desaparezca.
      loggy.info(
        'ProjectDetailController: ${project.id} ya no está disponible',
      );
      _detail.value = null;
      comments.clear();
      likeCount.value = 0;
      likedByMe.value = false;
      isUnavailable.value = true;
      errorMessage.value = '$exception';
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().getFeed();
      }
    } catch (exception) {
      loggy.error(
        'ProjectDetailController: error loading ${project.id}',
        exception,
      );
      _detail.value = null;
      errorMessage.value = 'No se pudo cargar la información del proyecto.';
    } finally {
      preview.value = null;
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

  /// Marcas que siguen escribiéndose: un segundo toque antes de que termine
  /// el primero crearía la fila dos veces.
  final _toggling = <RxBool>{};

  Future<void> toggleFollowing() async {
    await _toggleFlag(flag: isFollowing, action: _repository.toggleFollowing);
    final projectId = detail?.projectId;
    if (projectId != null && Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().markFollowed(
        projectId,
        followed: isFollowing.value,
      );
    }
  }

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

    if (!_toggling.add(flag)) return;
    final previous = flag.value;
    flag.value = !previous;
    actionError.value = '';
    try {
      flag.value = await action(projectId);
    } catch (exception) {
      loggy.error('ProjectDetailController: error toggling flag', exception);
      flag.value = previous;
      actionError.value = errors.errorMessage(exception);
    } finally {
      _toggling.remove(flag);
    }
  }

  /// Alterna el "me gusta" del proyecto abierto, optimista y con reversa si
  /// el servidor lo rechaza.
  Future<void> toggleLike() async {
    final projectId = detail?.projectId;
    if (projectId == null) return;

    if (!_toggling.add(likedByMe)) return;
    final wasLiked = likedByMe.value;
    likedByMe.value = !wasLiked;
    likeCount.value += wasLiked ? -1 : 1;
    try {
      likeCount.value = await _repository.toggleLike(projectId);
    } catch (exception) {
      loggy.error('ProjectDetailController: error toggling like', exception);
      likedByMe.value = wasLiked;
      likeCount.value += wasLiked ? 1 : -1;
    } finally {
      _toggling.remove(likedByMe);
    }
  }

  Future<void> submitComment(String content, {String? authorName}) async {
    final projectId = detail?.projectId;
    final text = content.trim();
    if (projectId == null || text.isEmpty) return;

    isSendingComment.value = true;
    try {
      final comment = await _repository.addComment(
        projectId,
        text,
        authorName: authorName,
      );
      comments.add(comment);
      await _notifyComment(comment, projectId);
    } catch (exception) {
      loggy.error('ProjectDetailController: error posting comment', exception);
    } finally {
      isSendingComment.value = false;
    }
  }

  /// Publica y la pone arriba del muro. False si no se pudo (el motivo
  /// queda en [actionError]).
  Future<bool> addPublication(Publication publication) =>
      _publicationAction(() async {
        final created = await _repository.createPublication(publication);
        publications.insert(0, created);
        await notify(
          type: created.isPoll
              ? NotificationType.pollActivity
              : NotificationType.projectUpdate,
          message:
              '${_projectName(created.projectId)} publicó "${created.title}".',
          projectId: created.projectId,
          // `polls` no es un avance: solo los avances van en `update_id`.
          updateId: created.isPoll ? null : created.id,
        );
      });

  Future<bool> updatePublication(Publication publication) =>
      _publicationAction(() async {
        await _repository.updatePublication(publication);
        _replacePublication(publication.id, (_) => publication);
      });

  Future<bool> deletePublication(Publication publication) =>
      _publicationAction(() async {
        await _repository.deletePublication(publication);
        publications.removeWhere((item) => item.id == publication.id);
      });

  Future<bool> addPublicationComment(Publication publication, String text) =>
      _publicationAction(() async {
        final comment = await _repository.addComment(
          publication.projectId,
          text,
          publicationId: publication.id,
        );
        _replacePublication(
          publication.id,
          (p) => p.copyWith(
            comments: [...p.comments, comment],
            commentCount: p.commentCount + 1,
          ),
        );
        await _notifyComment(
          comment,
          publication.projectId,
          updateId: publication.id,
        );
      });

  Future<void> _notifyComment(
    ProjectComment comment,
    String projectId, {
    String? updateId,
  }) {
    final text = comment.content.length > 80
        ? '${comment.content.substring(0, 80)}…'
        : comment.content;
    return notify(
      type: NotificationType.projectComment,
      message:
          '${comment.authorName} comentó en ${_projectName(projectId)}: '
          '"$text"',
      projectId: projectId,
      commentId: comment.id,
      updateId: updateId,
    );
  }

  /// Optimista: cambia en pantalla y, si el servidor lo rechaza, lo deshace.
  Future<void> togglePublicationReaction(Publication publication) async {
    if (!_togglingPublications.add(publication.id)) return;
    _replacePublication(
      publication.id,
      (p) => p.copyWith(
        viewerReacted: !p.viewerReacted,
        reactionCount: p.reactionCount + (p.viewerReacted ? -1 : 1),
      ),
    );
    final ok = await _publicationAction(() async {
      final count = await _repository.togglePublicationReaction(publication);
      _replacePublication(
        publication.id,
        (p) => p.copyWith(reactionCount: count),
      );
    });
    if (!ok) _replacePublication(publication.id, (_) => publication);
    _togglingPublications.remove(publication.id);
  }

  Future<void> votePublicationPoll(
    Publication publication,
    String option,
  ) async {
    if (publication.selectedPollOption == option ||
        !_togglingPublications.add(publication.id)) {
      return;
    }
    final votes = Map<String, int>.of(publication.pollVotes);
    final previous = publication.selectedPollOption;
    if (previous != null) votes[previous] = (votes[previous] ?? 1) - 1;
    votes[option] = (votes[option] ?? 0) + 1;
    _replacePublication(
      publication.id,
      (p) => p.copyWith(selectedPollOption: option, pollVotes: votes),
    );
    final ok = await _publicationAction(
      () => _repository.votePoll(publication, option),
    );
    if (!ok) _replacePublication(publication.id, (_) => publication);
    _togglingPublications.remove(publication.id);
  }

  /// Publicaciones con un me gusta o un voto en camino: un segundo toque
  /// duplicaría la fila.
  final _togglingPublications = <String>{};

  void _replacePublication(
    String id,
    Publication Function(Publication) change,
  ) {
    final index = publications.indexWhere((item) => item.id == id);
    if (index != -1) publications[index] = change(publications[index]);
  }

  Future<bool> _publicationAction(Future<void> Function() action) async {
    actionError.value = '';
    try {
      await action();
      return true;
    } catch (exception) {
      loggy.error('ProjectDetailController: publication action', exception);
      actionError.value = errors.errorMessage(exception);
      return false;
    }
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
    String? applicationId,
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

    await notify(
      type: NotificationType.applicationAccepted,
      recipientId: applicantId,
      message: 'Te aceptaron como $roleTitle en ${_projectName(projectId)}.',
      projectId: projectId,
      applicationId: applicationId,
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
  /// queda a cargo. Refresca "Mis Proyectos".
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

    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().getFeed();
    }
    isLeaving.value = false;
    return null;
  }

  String _projectName(String projectId) =>
      detail?.projectId == projectId ? detail!.name : 'el proyecto';
}
