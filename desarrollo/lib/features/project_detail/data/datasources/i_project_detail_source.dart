import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';

abstract class IProjectDetailSource {
  Future<ProjectDetail?> getDetail(String projectId);

  Future<void> saveDetail(ProjectDetail detail);

  /// Usuario en sesión, que es quien figura como creador de lo que publica.
  /// Provisional hasta conectar la feature de autenticación.
  Future<ProjectMember> getCurrentUser();
}
