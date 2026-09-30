/// Una comunidad con los proyectos que acoge.
///
/// Es el modelo propio de esta feature: el feed de inicio trabaja con su
/// `Community` resumida (nombre y última actividad) y aquí vive lo que hace
/// falta para la pantalla completa.
class CommunityDetail {
  const CommunityDetail({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.memberCount = 0,
    this.isMember = false,
    this.isOwner = false,
    this.projects = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? coverUrl;

  /// Filas activas de `community_members`.
  final int memberCount;

  /// Si quien mira ya sigue la comunidad.
  final bool isMember;

  /// Si quien mira la creó; es quien puede configurarla.
  final bool isOwner;

  /// Proyectos vinculados por `project_communities`, del más nuevo al más
  /// antiguo.
  final List<CommunityProject> projects;

  CommunityDetail copyWith({bool? isMember, int? memberCount}) =>
      CommunityDetail(
        id: id,
        name: name,
        description: description,
        coverUrl: coverUrl,
        memberCount: memberCount ?? this.memberCount,
        isMember: isMember ?? this.isMember,
        isOwner: isOwner,
        projects: projects,
      );
}

/// Un proyecto dentro del feed de la comunidad.
class CommunityProject {
  const CommunityProject({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.stage,
    this.tags = const [],
    this.memberCount = 0,
    this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String? stage;
  final List<String> tags;
  final int memberCount;
  final DateTime? createdAt;
}
