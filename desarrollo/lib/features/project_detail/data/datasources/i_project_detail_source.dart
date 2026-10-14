import '../../domain/models/project_comment.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';
import '../../domain/models/publication.dart';

abstract class IProjectDetailSource {
  Future<ProjectDetail?> getDetail(String projectId);

  /// [originalMemberIds]: línea base del equipo al abrir la configuración;
  /// solo esos usuarios pueden retirarse al guardar. Vacío no retira a nadie.
  Future<void> saveDetail(
    ProjectDetail detail, {
    Set<String> originalMemberIds = const {},
  });

  /// Usuario en sesión, que es quien figura como creador de lo que publica.
  Future<ProjectMember> getCurrentUser();

  /// Suma a [member] al equipo tras aceptar su postulación, ocupando el cupo
  /// [projectRoleId] o, si ya se llenó, otro libre del mismo rol.
  Future<void> addMember({
    required String projectId,
    required ProjectMember member,
    required String projectRoleId,
  });

  /// Saca del equipo al usuario en sesión, sin borrar su fila.
  ///
  /// Si lidera el proyecto, [newLeaderId] es obligatorio: el liderazgo pasa
  /// a ese integrante en la misma operación.
  Future<void> leaveProject({required String projectId, String? newLeaderId});

  /// Cuántos "me gusta" tiene el proyecto, y si quien mira ya dio uno.
  Future<({int count, bool likedByMe})> getLikeStatus(String projectId);

  /// Da o quita el "me gusta" de quien mira. Devuelve el total ya actualizado.
  Future<int> toggleLike(String projectId);

  /// Si quien mira ya guardó el proyecto y si lo sigue. Ambos false cuando
  /// no hay una cuenta detrás: un invitado no puede guardar ni seguir.
  Future<({bool saved, bool following})> getViewerFlags(String projectId);

  /// Guarda o quita el proyecto de los guardados. Devuelve el estado nuevo.
  Future<bool> toggleSaved(String projectId);

  /// Sigue o deja de seguir el proyecto. Devuelve el estado nuevo.
  Future<bool> toggleFollowing(String projectId);

  Future<List<ProjectComment>> getComments(String projectId);

  Future<ProjectComment> addComment(
    String projectId,
    String content, {
    String? authorName,
    String? publicationId,
  });

  /// Publicaciones del muro, de la más nueva a la más vieja.
  Future<List<Publication>> getPublications(String projectId);

  /// Publica [publication] y la devuelve con el id que le dio el servidor.
  Future<Publication> createPublication(Publication publication);

  /// Guarda título, texto, imagen y enlace. Las opciones de una encuesta no
  /// se tocan: ya puede tener votos.
  Future<void> updatePublication(Publication publication);

  Future<void> deletePublication(Publication publication);

  /// Da o quita el "me gusta" de quien mira. Devuelve el total ya actualizado.
  Future<int> togglePublicationReaction(Publication publication);

  /// Vota [option] en la encuesta; si ya había votado, cambia su voto.
  Future<void> votePoll(Publication publication, String option);

  /// Elimina o archiva lógicamente el proyecto.
  Future<void> deleteProject(String projectId);
}
