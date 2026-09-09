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

  /// Whether to show the "NUEVO" badge on the card.
  // TODO: validar con usuarios — la ventana de 7 días es un supuesto de UX
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
    );
  }
}
