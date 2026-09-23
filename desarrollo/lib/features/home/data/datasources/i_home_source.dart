import '../../domain/models/community.dart';
import '../../domain/models/home_feed.dart';
import '../../domain/models/project.dart';

abstract class IHomeSource {
  Future<HomeFeed> getFeed();

  /// Añade un proyecto recién publicado a "Mis Proyectos". Ver
  /// [IHomeRepository.addProject] para por qué lleva parámetros aparte.
  Future<Project> addProject(
    Project project, {
    required String problem,
    required String objective,
    String? scope,
    required int maxMembers,
    required String availability,
  });

  /// Añade una comunidad recién creada a las comunidades que sigue el usuario.
  Future<void> addCommunity(Community community);

  /// Reemplaza un proyecto ya existente, p. ej. tras editarlo en su
  /// configuración.
  Future<void> updateProject(Project project);
}
