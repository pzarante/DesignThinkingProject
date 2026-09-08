class Community {
  const Community({required this.id, required this.name, this.lastActivity});

  final String id;
  final String name;

  /// Short human-readable summary of recent activity, e.g.
  /// "3 publicaciones nuevas". Null falls back to showing just the name
  /// (no activity to report yet).
  final String? lastActivity;
}
