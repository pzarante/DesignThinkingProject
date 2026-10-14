import 'community.dart';
import 'opportunity.dart';
import 'project.dart';

/// Everything the home screen shows, resolved in a single read.
class HomeFeed {
  const HomeFeed({
    required this.followedCommunities,
    required this.recommendedProjects,
    required this.opportunities,
    required this.myProjects,
    this.savedProjects = const [],
    this.followedProjectIds = const {},
  });

  const HomeFeed.empty()
    : followedCommunities = const [],
      recommendedProjects = const [],
      opportunities = const [],
      myProjects = const [],
      savedProjects = const [],
      followedProjectIds = const {};

  final List<Community> followedCommunities;
  final List<Project> recommendedProjects;
  final List<Opportunity> opportunities;
  final List<Project> myProjects;

  /// Proyectos de otros que esta persona marcó como guardados
  /// (`project_saved`). Vacío sin cuenta: guardar exige una.
  final List<Project> savedProjects;

  /// Ids de los proyectos que esta persona sigue (`project_followers`). Sirven
  /// para poner esos proyectos primero en el home; Explorar no los prioriza.
  final Set<String> followedProjectIds;

  HomeFeed withFollowed(String projectId, {required bool followed}) => HomeFeed(
    followedCommunities: followedCommunities,
    recommendedProjects: recommendedProjects,
    opportunities: opportunities,
    myProjects: myProjects,
    savedProjects: savedProjects,
    // Un `if` y no `a ? b : c..remove()`: el cascade se aplicaría a toda la
    // condicional y borraría el id recién añadido.
    followedProjectIds: {
      for (final id in followedProjectIds)
        if (id != projectId) id,
      if (followed) projectId,
    },
  );

  /// Proyectos anclados y/o los 2 visitados más recientemente, para la
  /// versión resumida de "Mis Proyectos" en el Home (validado semana 5).
  /// Anclados van primero; si hay espacio, se completa con los más
  /// recientes que no estén ya incluidos.
  ///
  /// Las postulaciones pendientes no cuentan: todavía no es un proyecto
  /// propio.
  List<Project> get myProjectsSummary {
    final own = myProjects.where(
      (p) => p.myRelation != MyProjectRelation.pendingApplication,
    );
    final pinned = own.where((p) => p.isPinned).toList();

    final recentCandidates =
        own.where((p) => !p.isPinned && p.lastVisitedAt != null).toList()
          ..sort((a, b) => b.lastVisitedAt!.compareTo(a.lastVisitedAt!));

    final remainingSlots = (2 - pinned.length).clamp(0, 2);
    return [...pinned, ...recentCandidates.take(remainingSlots)];
  }
}
