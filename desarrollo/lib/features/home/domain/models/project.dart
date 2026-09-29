/// Relación de quien tiene la sesión con un proyecto de "Mis Proyectos".
enum MyProjectRelation {
  /// Lo lidera (`project_members.is_creator`).
  creator,

  /// Forma parte del equipo, pero lo lidera otra persona.
  member,

  /// Tiene una postulación pendiente a una de sus vacantes.
  pendingApplication,
}

class Project {
  const Project({
    required this.id,
    required this.name,
    this.tags = const [], // temática
    this.stage, // etapa del proyecto
    this.memberCount = 0,
    this.isPinned = false,
    this.lastVisitedAt,
    this.imageUrl,
    this.createdAt,
    this.description,
    this.requiredRoles = const [],
    this.myRelation,
  });

  final String id;
  final String name;
  final List<String> tags;

  /// Where the project stands today, e.g. "Prototipo" o "Investigación".
  final String? stage;
  final int memberCount;

  /// Manually pinned by the user from "Mis Proyectos".
  final bool isPinned;

  /// Last time the user opened this project's detail screen.
  /// Null means it has never been visited since creation/tracking started.
  final DateTime? lastVisitedAt;

  /// Cover image URL. Null falls back to the placeholder cover.
  final String? imageUrl;

  /// When the project was published. Null for mock projects that predate
  /// this field (treated as not-new).
  final DateTime? createdAt;

  /// Short description shown in the project detail screen.
  final String? description;
  final List<String> requiredRoles;

  /// Solo en "Mis Proyectos". Null en el feed y en los datos en memoria,
  /// donde todo lo propio se trata como creado por el usuario.
  final MyProjectRelation? myRelation;

  /// Whether to show the "NUEVO" badge on the card.
  //
  // no especificado en PROJECT_SPEC.md, no un dato validado en investigación.
  bool get isNew {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt!).inDays <= 7;
  }

  Project copyWith({
    String? id,
    String? name,
    List<String>? tags,
    String? stage,
    int? memberCount,
    bool? isPinned,
    DateTime? lastVisitedAt,
    String? imageUrl,
    DateTime? createdAt,
    String? description,
    List<String>? requiredRoles,
    MyProjectRelation? myRelation,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      tags: tags ?? this.tags,
      stage: stage ?? this.stage,
      memberCount: memberCount ?? this.memberCount,
      isPinned: isPinned ?? this.isPinned,
      lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      requiredRoles: requiredRoles ?? this.requiredRoles,
      myRelation: myRelation ?? this.myRelation,
    );
  }
}
