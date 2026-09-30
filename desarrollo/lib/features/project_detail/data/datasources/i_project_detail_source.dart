import '../../domain/models/project_comment.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';

abstract class IProjectDetailSource {
  Future<ProjectDetail?> getDetail(String projectId);

  Future<void> saveDetail(ProjectDetail detail);

  /// Usuario en sesión, que es quien figura como creador de lo que publica.
  Future<ProjectMember> getCurrentUser();

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

  Future<ProjectComment> addComment(String projectId, String content);
}
