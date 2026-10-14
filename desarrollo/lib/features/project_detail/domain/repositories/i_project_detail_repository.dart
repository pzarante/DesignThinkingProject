import '../models/project_comment.dart';
import '../models/project_detail.dart';
import '../models/project_member.dart';

abstract class IProjectDetailRepository {
  /// Detalle guardado de un proyecto, o null si todavía no tiene uno.
  ///
  /// Lanza `ProjectUnavailableException` si el proyecto se borró.
  Future<ProjectDetail?> getDetail(String projectId);

  /// Guarda el detalle recién creado o editado desde la configuración.
  ///
  /// [originalMemberIds] es la línea base del equipo: quiénes estaban activos
  /// cuando se abrió la configuración. Solo a ellos se les puede retirar al
  /// guardar; quien entró después no está en la copia que se edita y no debe
  /// salir por eso. Vacío (un proyecto nuevo) no retira a nadie.
  Future<void> saveDetail(
    ProjectDetail detail, {
    Set<String> originalMemberIds = const {},
  });

  /// Usuario en sesión, que es quien figura como creador de lo que publica.
  Future<ProjectMember> getCurrentUser();

  /// Suma a [member] al equipo tras aceptar su postulación, ocupando el cupo
  /// [projectRoleId] o, si ya se llenó, otro libre del mismo rol. Si el rol
  /// ya no existe, entra igual pero sin ocupar cupo.
  Future<void> addMember({
    required String projectId,
    required ProjectMember member,
    required String projectRoleId,
  });

  /// Saca del equipo al usuario en sesión. La fila queda como historial
  /// (`status` y `left_at`), no se borra.
  ///
  /// Si lidera el proyecto, [newLeaderId] es obligatorio: el liderazgo pasa
  /// a ese integrante activo en la misma operación.
  Future<void> leaveProject({required String projectId, String? newLeaderId});

  /// Cuántos "me gusta" tiene el proyecto, y si quien mira ya dio uno.
  Future<({int count, bool likedByMe})> getLikeStatus(String projectId);

  /// Da o quita el "me gusta" de quien mira. Devuelve el total ya actualizado.
  Future<int> toggleLike(String projectId);

  /// Si quien mira ya guardó el proyecto y si lo sigue.
  Future<({bool saved, bool following})> getViewerFlags(String projectId);

  /// Guarda o quita el proyecto de los guardados. Devuelve el estado nuevo.
  Future<bool> toggleSaved(String projectId);

  /// Sigue o deja de seguir el proyecto. Devuelve el estado nuevo.
  Future<bool> toggleFollowing(String projectId);

  /// Comentarios públicos del proyecto, del más antiguo al más nuevo.
  Future<List<ProjectComment>> getComments(String projectId);

  /// Publica un comentario propio y lo devuelve ya creado.
  Future<ProjectComment> addComment(
    String projectId,
    String content, {
    String? authorName,
  });

  /// Elimina o archiva lógicamente el proyecto.
  Future<void> deleteProject(String projectId);
}
