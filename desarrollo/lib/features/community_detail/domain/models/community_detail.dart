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
    this.followerCount = 0,
    this.isFollowing = false,
    this.isOwner = false,
    this.projects = const [],
  });

  final String id;
  final String name;
  final String? description;
  final String? coverUrl;

  /// Personas distintas con membresía activa en al menos un proyecto de la
  /// comunidad (`project_members` vía `project_communities`).
  final int memberCount;

  /// Filas activas de `community_members`: quienes siguen la comunidad sin
  /// pertenecer necesariamente a ella.
  final int followerCount;

  /// Si quien mira ya sigue la comunidad (fila activa suya en
  /// `community_members`). No implica participar en ninguno de sus proyectos.
  final bool isFollowing;

  /// Si quien mira la creó; es quien puede configurarla.
  final bool isOwner;

  /// Proyectos vinculados por `project_communities`, del más nuevo al más
  /// antiguo.
  final List<CommunityProject> projects;

  CommunityDetail copyWith({bool? isFollowing, int? followerCount}) =>
      CommunityDetail(
        id: id,
        name: name,
        description: description,
        coverUrl: coverUrl,
        memberCount: memberCount,
        followerCount: followerCount ?? this.followerCount,
        isFollowing: isFollowing ?? this.isFollowing,
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
