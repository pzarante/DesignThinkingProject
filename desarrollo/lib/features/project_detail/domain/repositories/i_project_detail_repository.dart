import '../models/project_detail.dart';
import '../models/project_member.dart';

abstract class IProjectDetailRepository {
  /// Detalle guardado de un proyecto, o null si todavía no tiene uno.
  Future<ProjectDetail?> getDetail(String projectId);

  /// Guarda el detalle recién creado o editado desde la configuración.
  Future<void> saveDetail(ProjectDetail detail);

  /// Usuario en sesión, que es quien figura como creador de lo que publica.
  /// Provisional hasta conectar la feature de autenticación.
  Future<ProjectMember> getCurrentUser();
}
