import '../models/project_comment.dart';
import '../models/project_detail.dart';
import '../models/project_member.dart';

abstract class IProjectDetailRepository {
  /// Detalle guardado de un proyecto, o null si todavía no tiene uno.
  Future<ProjectDetail?> getDetail(String projectId);

  /// Guarda el detalle recién creado o editado desde la configuración.
  Future<void> saveDetail(ProjectDetail detail);

  /// Usuario en sesión, que es quien figura como creador de lo que publica.
  Future<ProjectMember> getCurrentUser();

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
  Future<ProjectComment> addComment(String projectId, String content);
}
