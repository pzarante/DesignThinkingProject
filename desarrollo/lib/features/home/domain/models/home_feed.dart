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
  });

  const HomeFeed.empty()
    : followedCommunities = const [],
      recommendedProjects = const [],
      opportunities = const [],
      myProjects = const [];

  final List<Community> followedCommunities;
  final List<Project> recommendedProjects;
  final List<Opportunity> opportunities;
  final List<Project> myProjects;

  /// Proyectos anclados y/o los 2 visitados más recientemente, para la
  /// versión resumida de "Mis Proyectos" en el Home (validado semana 5).
  /// Anclados van primero; si hay espacio, se completa con los más
  /// recientes que no estén ya incluidos.
  List<Project> get myProjectsSummary {
    final pinned = myProjects.where((p) => p.isPinned).toList();

    final recentCandidates =
        myProjects.where((p) => !p.isPinned && p.lastVisitedAt != null).toList()
          ..sort((a, b) => b.lastVisitedAt!.compareTo(a.lastVisitedAt!));

    final remainingSlots = (2 - pinned.length).clamp(0, 2);
    return [...pinned, ...recentCandidates.take(remainingSlots)];
  }
}
