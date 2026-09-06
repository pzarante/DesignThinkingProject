class Project {
  const Project({
    required this.id,
    required this.name,
    this.tags = const [],
    this.stage,
    this.memberCount = 0,
  });

  final String id;
  final String name;
  final List<String> tags;

  /// Where the project stands today, e.g. "Prototipo" or "Investigación".
  final String? stage;
  final int memberCount;
}
