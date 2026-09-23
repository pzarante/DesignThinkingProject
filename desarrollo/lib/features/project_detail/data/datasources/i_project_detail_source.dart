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

  Future<List<ProjectComment>> getComments(String projectId);

  Future<ProjectComment> addComment(String projectId, String content);
}
