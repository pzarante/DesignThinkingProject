class Community {
  const Community({
    required this.id,
    required this.name,
    this.lastActivity,
    this.tags = const [],
    this.description,
    this.coverUrl,
    this.isPublic = true,
    this.projectIds = const [],
  });

  final String id;
  final String name;

  /// Short human-readable summary of recent activity, e.g.
  /// "3 publicaciones nuevas". Null falls back to showing just the name
  /// (no activity to report yet).
  final String? lastActivity;

  /// Category tags, part of the same shared tag system used by [Project]
  /// (PROJECT_SPEC.md sección 2).
  final List<String> tags;

  /// Descripción que escribe quien la crea. Null en las comunidades
  /// sembradas, que solo tenían nombre y actividad.
  final String? description;

  /// Portada de la comunidad. Null cae en el placeholder.
  final String? coverUrl;

  /// Pública = cualquier estudiante puede unirse libremente.
  final bool isPublic;

  /// Proyectos vinculados a la comunidad (ids de [Project]).
  final List<String> projectIds;

  Community copyWith({
    String? id,
    String? name,
    String? lastActivity,
    List<String>? tags,
    String? description,
    String? coverUrl,
    bool? isPublic,
    List<String>? projectIds,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      lastActivity: lastActivity ?? this.lastActivity,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      isPublic: isPublic ?? this.isPublic,
      projectIds: projectIds ?? this.projectIds,
    );
  }
}
