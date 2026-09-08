class Community {
  const Community({
    required this.id,
    required this.name,
    this.lastActivity,
    this.tags = const [],
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
}
