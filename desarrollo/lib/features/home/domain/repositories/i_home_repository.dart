import '../models/community.dart';
import '../models/home_feed.dart';
import '../models/project.dart';

abstract class IHomeRepository {
  Future<HomeFeed> getFeed();

  /// [Project] solo trae el resumen de la tarjeta; `problem`/`objective` son
  /// columnas obligatorias de `projects` en ROBLE que el borrador sí conoce
  /// pero la entidad del feed no. Devuelve el proyecto ya con el id real que
  /// asigna el servidor: `project.id` al llamar es un valor de relleno.
  Future<Project> addProject(
    Project project, {
    required String problem,
    required String objective,
    String? scope,
    required int maxMembers,
    required String availability,
    String? coLeaderId,
    List<String> links = const [],
  });

  Future<void> addCommunity(Community community);

  Future<void> updateProject(Project project);
}
