class Project {
  const Project({
    required this.id,
    required this.name,
    this.tags = const [],
    this.stage,
    this.memberCount = 0,
    this.isPinned = false,
    this.lastVisitedAt,
    this.imageUrl,
    this.createdAt,
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

  /// Whether to show the "NUEVO" badge on the card.
  // TODO: validar con usuarios — la ventana de 7 días es un supuesto de UX
  // no especificado en PROJECT_SPEC.md, no un dato validado en investigación.
  bool get isNew {
    if (createdAt == null) return false;
    return DateTime.now().difference(createdAt!).inDays <= 7;
  }
}
